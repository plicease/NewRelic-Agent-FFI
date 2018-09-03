package NewRelic::Agent::FFI;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus 0.56;
use Alien::nragent;
use FFI::CheckLib ();

# ABSTRACT: Perl Agent for NewRelic APM
# VERSION

=head1 SYNOPSIS

 use NewRelic::Agent::FFI;
 
 my $agent = NewRelic:Agent::FFI->new(
   license_key => 'abc123',
   app_name    => 'REST API',
 );
 
 $agent->embed_collector;
 $agent->init;
 my $txn_id = $agent->begin_transaction;
 ...
 my $err_id = $agent->end_transaction($txn_id);

=head1 DESCRIPTION

This module provides bindings for the L<NewRelic|https://docs.newrelic.com/docs/agents/agent-sdk/getting-started/new-relic-agent-sdk> Agent SDK.

It is a drop in replacement for L<NewRelic::Agent> that is implemented using L<FFI::Platypus> instead of XS and C++.

Why use this module instead of the other one?

=over 4

=item Powerful L<Alien> technology

This module uses L<Alien::nragent> to either download the NR agent or to use a locally installed copy.  The other module has
L<a serious bug which will break when the install files are removed|https://github.com/aanari/NewRelic-Agent/issues/2>!  You
can choose the version of the NR SDK that you want to use instead of relying on the maintainer of L<NewRelic::Agent> to do so.

=item Possible license issues

Related to the last point, the other module bundles the NR SDK, which may have legal risks (I am not a lawyer).  In the very least
I think goes against the Open Source philosophy of CPAN.

=item No C++ compiler required!

Since this module is built with powerful FFI and Platypus technology, you don't need to build XS bindings for it.  The
other module has its bindings written in C++, which is IMO unnecessary and doesn't add anything.

=item Tests!

The test suite for L<NewRelic::Agent> is IMO insufficient to have confidence in it, especially if the SDK needs to be upgraded.
This module comes with a number of tests that will at least make sure that the calls to NewRelic will not crash your application.
The live test can even be configured (not on by default) to send data to NR so that you can be sure it works.

=item Active Development

At least as of this writing, this module is being actively developed.  The other module has a number of unanswered open issues,
bugs and pull requests.

=back

Why use the other module instead of this one?

=over 4

=item This module is newer

The other module has been around for longer, and may have been used in production more.  Peoples will probably have noticed if it
were broken by now.

=back

=head1 CONSTRUCTOR

=head2 new

 my $agent = NewRelic::Agent::FFI->new(%options);

Instantiates a new NewRelic::Agent client object.  Options include:

=over 4

=item C<license_key>

A valid NewRelic license key for your account.

This value is also automatically sourced from the C<NEWRELIC_LICENSE_KEY> environment variable.

=item C<app_name>

The name of your application.

This value is also automatically sourced from the C<NEWRELIC_APP_NAME> environment variable.

=item C<app_language>

The language that your application is written in.

This value defaults to C<perl>, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE> environment variable.

=item C<app_language_version>

The version of the language that your application is written in.

This value defaults to your perl version, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE_VERSION> environment variable.

=back

=cut

sub new
{
  my($class, %args) = @_;
  
  my $license_key          = delete $args{license_key}
                          || $ENV{NEWRELIC_LICENSE_KEY}
                          || '';
  my $app_name             = delete $args{app_name}
                          || $ENV{NEWRELIC_APP_NAME}
                          || 'AppName';
  my $app_language         = delete $args{app_language}
                          || $ENV{NEWRELIC_APP_LANGUAGE}
                          || 'perl';
  my $app_language_version = delete $args{app_language_version}
                          || $ENV{NEWRELIC_APP_LANGUAGE_VERSION}
                          || $];

  if (%args) {
    require Carp;
    Carp::croak("Invalid arguments: @{[ keys %args ]}");
  }  
  
  bless {
    license_key          => $license_key,
    app_name             => $app_name,
    app_language         => $app_language,
    app_language_version => $app_language_version,
  }, $class;
}

my $ffi = FFI::Platypus->new;
$ffi->lib(sub {
  my @find_lib_args = (
    lib => [ qw(newrelic-collector-client newrelic-common newrelic-transaction) ]
  );
  push @find_lib_args, libpath => ['/opt/newrelic/lib/'] if -d '/opt/newrelic/lib/';
  my @system = FFI::CheckLib::find_lib(@find_lib_args);
  return @system if @system;
  require Alien::nragent;
  Alien::nragent->dynamic_libs;
});
my $newrelic_basic_literal_replacement_obfuscator = $ffi->find_symbol('newrelic_basic_literal_replacement_obfuscator');

=head1 METHODS

Methods noted below that return C<$status> return 0 for success or non-zero for failure.  See the NR SDK documentation for error codes.

=head2 embed_collector

 $agent->embed_collector;

Embeds the collector agent for harvesting NewRelic data. This should be called before C<init>, if the agent is being used in Embedded mode and not Daemon mode.

=cut

sub embed_collector
{
  my($self) = @_;
  my $newrelic_message_handler = $ffi->find_symbol('newrelic_message_handler');
  if($newrelic_message_handler)
  {
    $ffi->function('newrelic_register_message_handler' => ['opaque'] => 'void')->call($newrelic_message_handler);
  }
  else
  {
    Carp::croak("unable to find newrelic_message_handler");
  }
}

=head2 init

 my $status = $agent->init;

Initialize the connection to NewRelic.

=cut

$ffi->attach( [ newrelic_init => 'init' ] => [ 'string', 'string', 'string', 'string' ] => 'int' => sub {
  my($xsub, $self) = @_;
  $xsub->(
    $self->get_license_key,
    $self->get_app_name,
    $self->get_app_language,
    $self->get_app_language_version,
  );
});

=head2 begin_transaction

 my $tx = $agent->begin_transaction;

Identifies the beginning of a transaction, which is a timed operation consisting of multiple segments. By default, transaction type is set to C<WebTransaction> and transaction category is set to C<Uri>.

Returns the transaction's ID on success, else negative warning code or error code.

=cut

$ffi->attach( [ newrelic_transaction_begin => 'begin_transaction' ] => [] => 'long' => sub {
  shift->();
});

sub _set1
{
  $_[0]->($_[2]);
}

sub _set2
{
  $_[0]->(@_[2,3]);
}

sub _set3
{
  $_[0]->(@_[2,3,4]);
}

=head2 set_transaction_name

 my $status = $agent->set_transaction_name($tx, $name);

Sets the transaction name.

=head2 set_transaction_request_url

 my $status = $agent->set_transaction_request_url($tx, $url);

Sets the transaction URL.

=head2 set_transaction_max_trace_segments

 my $status = $agent->set_transaction_max_trace_segments($tx, $max);

Sets the maximum trace section for the transaction.

=head2 set_transaction_category

 my $status = $agent->set_transaction_type_web($tx);

Sets the transaction type to 'web'

=head2 set_transaction_type_web

 my $status = $agent->set_transaction_type_other($tx);

Sets the transaction type to 'other'

=head2 add_transaction_attribute

 my $status = $agent->add_transaction_attribute($tx, $key => $value);

Adds the given attribute (key/value pair) for the transaction.

=cut

$ffi->attach( [ newrelic_transaction_set_name               => 'set_transaction_name'               ] => [ 'long', 'string' ] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_transaction_set_request_url        => 'set_transaction_request_url'        ] => [ 'long', 'string' ] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_transaction_set_max_trace_segments => 'set_transaction_max_trace_segments' ] => [ 'long', 'int'    ] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_transaction_set_category           => 'set_transaction_category'           ] => [ 'long', 'string' ] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_transaction_set_type_web   => 'set_transaction_type_web'   ] => [ 'long' ] => 'int' => \&_set1 );
$ffi->attach( [ newrelic_transaction_set_type_other => 'set_transaction_type_other' ] => [ 'long' ] => 'int' => \&_set1 );
$ffi->attach( [ newrelic_transaction_add_attribute => 'add_transaction_attribute' ] => [ 'long', 'string', 'string' ] => 'int' => \&_set3);

=head2 notice_transaction_error

 my $status = $agent->notice_transaction_error($tx, $exception_type, $error_message, $stack_trace, $stack_frame_delimiter);

Identify an error that occurred during the transaction. The first identified
error is sent with each transaction.

=cut

$ffi->attach( [ newrelic_transaction_notice_error => 'notice_transaction_error' ] => [ 'long', 'string', 'string', 'string', 'string' ] => 'int' => sub {
  my $xsub = shift;
  my $self = shift;
  $xsub->(@_);
});

=head2 end_transaction

 my $status = $agent->end_transaction($tx);

=head2 record_metric

 my $status = $agent->record_metric($key => $value);

Records the given metric (key/value pair).  The C<$value> should be a floating point.

=head2 record_cpu_usage

 my $status = $agent->record_cpu_usage($cpu_user_time_seconds, $cpu_usage_percent);

Records the CPU usage. C<$cpu_user_time_seconds> and C<$cpu_usage_percent> are floating point values.

=head2 record_memory_usage

 my $status = $agent->record_memory_usage($memory_megabytes);

Records the memory usage. C<$memory_megabytes> is a floating point value.

=cut

$ffi->attach( [ newrelic_transaction_end => 'end_transaction' ] => [ 'long' ] => 'int' => \&_set1 );
$ffi->attach( [ newrelic_record_metric => 'record_metric' ] => [ 'string', 'double'] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_record_cpu_usage => 'record_cpu_usage' ] => [ 'double', 'double' ] => 'int' => \&_set2);
$ffi->attach( [ newrelic_record_memory_usage => 'record_memory_usage' ] => [ 'double' ] => 'int' => \&_set1);

=head2 begin_generic_segment

 my $seg = $agent->begin_generic_segment($tx, $parent_seg, $name);

Begins a new generic segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).  C<$name> is a string.

=cut

$ffi->attach( [ newrelic_segment_generic_begin => 'begin_generic_segment' ] => [ 'long', 'long', 'string' ] => 'long' => sub {
  my $xsub = shift;
  my $self = shift;
  $xsub->(@_);
});

=head2 begin_datastore_segment

 my $seg = $agent->begin_datastore_segment($tx, $parent_seg, $table, $operation, $sql, $sql_trace_rollup_name);

Begins a new datastore segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).

=cut

$ffi->attach( [ newrelic_segment_datastore_begin => 'begin_datastore_segment' ] => [ 'long', 'long', 'string', 'string', 'string', 'string', 'opaque' ] => 'long' => sub {
  $_[0]->(@_[2,3,4,5,6,7], $newrelic_basic_literal_replacement_obfuscator);
});

=head2 begin_external_segment

 my $seg = $agent->begin_external_segment($tx, $parent_seg, $host, $name);

Begins a new external segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).

=cut

$ffi->attach( [ newrelic_segment_external_begin => 'begin_external_segment' ] => [ 'long', 'long', 'string', 'string' ] => 'long' => sub {
  my $xsub = shift;
  my $self = shift;
  $xsub->(@_);
});

=head2 end_segment

 my $status = $agent->end_segment($tx, $seg);

End the given segment.

=cut

$ffi->attach( [ newrelic_segment_end => 'end_segment' ] => [ 'long', 'long' ] => 'int' => \&_set2);

=head2 get_license_key

 my $key = $agent->get_license_key;

Get the license key.

=head2 get_app_name

 my $name = $agent->get_app_name;

Get the application name.

=head2 get_app_language

 my $lang = $agent->get_app_language;

Get the language name (usually C<perl>).

=head2 get_app_language_version

 my $version = $agent->get_app_language_version;

Get the language version.

=cut

sub get_license_key { shift->{license_key} }
sub get_app_name { shift->{app_name} }
sub get_app_language { shift->{app_language} }
sub get_app_language_version { shift->{app_language_version} }

1;

=head2 CAVEATS

This module attempts to replicate the same interface as L<NewRelic::Agent>, and this module includes a superset of the same tests.  
Unfortunately, the existing test suite for L<NewRelic::Agent> is completely insufficient to have a high degree of confidence that
either module works.

=cut

package NewRelic::Agent::FFI;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus;
use Alien::nragent;

# ABSTRACT: Perl Agent for NewRelic APM
# VERSION

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
$ffi->lib(Alien::nragent->dynamic_libs);
my $newrelic_basic_literal_replacement_obfuscator = $ffi->find_symbol('newrelic_basic_literal_replacement_obfuscator');

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

$ffi->attach( [ newrelic_init => 'init' ] => [ 'string', 'string', 'string', 'string' ] => 'int' => sub {
  my($xsub, $self) = @_;
  $xsub->(
    $self->get_license_key,
    $self->get_app_name,
    $self->get_app_language,
    $self->get_app_language_version,
  );
});

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

$ffi->attach( [ newrelic_transaction_set_name               => 'set_transaction_name'               ] => [ 'long', 'string' ] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_transaction_set_request_url        => 'set_transaction_request_url'        ] => [ 'long', 'string' ] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_transaction_set_max_trace_segments => 'set_transaction_max_trace_segments' ] => [ 'long', 'int'    ] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_transaction_set_category           => 'set_transaction_category'           ] => [ 'long', 'string' ] => 'int' => \&_set2 );


$ffi->attach( [ newrelic_transaction_set_type_web   => 'set_transaction_type_web'   ] => [ 'long' ] => 'int' => \&_set1 );
$ffi->attach( [ newrelic_transaction_set_type_other => 'set_transaction_type_other' ] => [ 'long' ] => 'int' => \&_set1 );

$ffi->attach( [ newrelic_transaction_add_attribute => 'add_transaction_attribute' ] => [ 'long', 'string', 'string' ] => 'int' => \&_set3);

$ffi->attach( [ newrelic_transaction_notice_error => 'notice_transaction_error' ] => [ 'long', 'string', 'string', 'string', 'string' ] => 'int' => sub {
  my $xsub = shift;
  my $self = shift;
  $xsub->(@_);
});

$ffi->attach( [ newrelic_transaction_end => 'end_transaction' ] => [ 'long' ] => 'int' => \&_set1 );
$ffi->attach( [ newrelic_record_metric => 'record_metric' ] => [ 'string', 'double'] => 'int' => \&_set2 );
$ffi->attach( [ newrelic_record_cpu_usage => 'record_cpu_usage' ] => [ 'double', 'double' ] => 'int' => \&_set2);
$ffi->attach( [ newrelic_record_memory_usage => 'record_memory_usage' ] => [ 'double' ] => 'int' => \&_set1);

$ffi->attach( [ newrelic_segment_generic_begin => 'begin_generic_segment' ] => [ 'long', 'long', 'string' ] => 'long' => sub {
  my $xsub = shift;
  my $self = shift;
  $xsub->(@_);
});

$ffi->attach( [ newrelic_segment_datastore_begin => 'begin_datastore_segment' ] => [ 'long', 'long', 'string', 'string', 'string', 'string', 'opaque' ] => 'long' => sub {
  $_[0]->(@_[2,3,4,5,6,7], $newrelic_basic_literal_replacement_obfuscator);
});

$ffi->attach( [ newrelic_segment_external_begin => 'begin_external_segment' ] => [ 'long', 'long', 'string', 'string' ] => 'long' => sub {
  my $xsub = shift;
  my $self = shift;
  $xsub->(@_);
});

$ffi->attach( [ newrelic_segment_end => 'end_segment' ] => [ 'long', 'long' ] => 'int' => \&_set2);

sub get_license_key { shift->{license_key} }
sub get_app_name { shift->{app_name} }
sub get_app_language { shift->{app_language} }
sub get_app_language_version { shift->{app_language_version} }

1;

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

B<WARNING>: This module should be considered Alpha Quality!

This module provides bindings for the L<NewRelic|https://docs.newrelic.com/docs/agents/agent-sdk/getting-started/new-relic-agent-sdk> Agent SDK.

It is a drop in replacement for L<NewRelic::Agent> that is implemented using L<FFI::Platypus> instead of XS and C++.

Why use this module instead of the other one?
As of this writing, you should definitely not use it in production!  See the warning above and the caveats below.
One advantage is that this module uses powerful L<Alien> technology to source the NewRelic agent libraries.  The other module
has L<a serious bug which will break when the install files are removed|https://github.com/aanari/NewRelic-Agent/issues/2>.
Another advantage to this module is that it does not require a C++ compiler, or even a C compiler for that matter.  I think
requiring C++ is overkill for using the NewRelic SDK.

=head2 CAVEATS

This module attempts to replicate the same interface as L<NewRelic::Agent>, and this module includes a superset of the same tests.  
Unfortunately, the existing test suite for L<NewRelic::Agent> is completely insufficient to have a high degree of confidence that
either module works.

=cut

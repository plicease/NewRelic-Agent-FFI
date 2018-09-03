package NewRelic::Agent::FFI::Procedural;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus 0.56;
use FFI::Platypus::DL;
use FFI::CheckLib qw( find_lib );
use base qw( Exporter );

# ABSTRACT: Procedural interface for NewRelic APM
# VERSION

=head1 SYNOPSIS

 use NewRelic::Agent::FFI::Procedural;
 
 newrelic_init
   'abc123'     # license key
   'REST API'   # app name
 ;
 
 my $tx_id = newrelic_transaction_begin;
 ...
 my $err_id = newrelic_transaction_end $tx;

=head1 DESCRIPTION

This module provides bindings for the L<NewRelic|https://docs.newrelic.com/docs/agents/agent-sdk/getting-started/new-relic-agent-sdk> Agent SDK.

Unlike L<NewRelic::Agent::FFI>, this is NOT a drop in replacement for L<NewRelic::Agent>.  The author believes this interface is better.
In addition to the reasons the author believes L<NewRelic::Agent::FFI> to be better than L<NewRelic::Agent> (listed in the former's documentation),
the author believes this module to be better than L<NewRelic::Agent::FFI> because:

=over 4

=item Object oriented interface does represent or add anything

The L<NewRelic::Agent> instance that you create doesn't represent anything in the NewRelic Agent SDK.  In fact if you don't understand
how things work under the hood, you might be confused into believing that you can initialize agent instances in the same process.

=item Object oriented interface is slower

Because the C<$agent> instance needs to be shifted off the stack before calling the underlying C code there is a lot more overhead in the
object oriented interface.

=item Functions aren't renamed

The object oriented version renames a number of its methods, meaning you have to look at the source code to understand what parts of the
SDK you are I<actually> calling.  With this interface you can lookup the SDK functions in its documentation directly.

=back

=cut

our $ffi = FFI::Platypus->new;
$ffi->lib(sub {
  my @find_lib_args = (
    lib => [ qw(newrelic-collector-client newrelic-common newrelic-transaction) ]
  );
  push @find_lib_args, libpath => ['/opt/newrelic/lib/'] if -d '/opt/newrelic/lib/';
  my @system = find_lib(@find_lib_args);
  if(@system)
  {
    my($common) = grep /newrelic-common/, @system;
    my $handle = dlopen($common, RTLD_NOW | RTLD_GLOBAL ) || die "error dlopen $common @{[ dlerror ]}";
    return @system;
  }
  require Alien::nragent;
  Alien::nragent->dynamic_libs;
});

=head1 FUNCTIONS

=head2 newrelic_init

 my $status = newrelic_init $license_key, $app_name, $app_language, $app_language_version;

Initialize the connection to NewRelic.

=over 4

=item C<$license_key>

A valid NewRelic license key for your account.

This value is also automatically sourced from the C<NEWRELIC_LICENSE_KEY> environment variable.

=item C<$app_name>

The name of your application.

This value is also automatically sourced from the C<NEWRELIC_APP_NAME> environment variable.

=item C<$app_language>

The language that your application is written in.

This value defaults to C<perl>, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE> environment variable.

=item C<$app_language_version>

The version of the language that your application is written in.

This value defaults to your perl version, and can also be automatically sourced from the C<NEWRELIC_APP_LANGUAGE_VERSION> environment variable.

=back

=cut

$ffi->attach( newrelic_init => [ 'string', 'string', 'string', 'string' ] => 'int' => sub {
  my($xsub, $license_key, $app_name, $app_language, $app_language_version) = @_;
  
  $license_key          ||= $ENV{NEWRELIC_LICENSE_KEY}          || '';
  $app_name             ||= $ENV{NEWRELIC_APP_NAME}             || 'AppName';
  $app_language         ||= $ENV{NEWRELIC_APP_LANGUAGE}         || 'perl';
  $app_language_version ||= $ENV{NEWRELIC_APP_LANGUAGE_VERSION} || $];
  
  $xsub->($license_key, $app_name, $app_language, $app_language_version);
});

=head2 newrelic_transaction_begin

 my $tx = newrelic_transaction_begin;

Identifies the beginning of a transaction, which is a timed operation consisting of multiple segments. By default, transaction type is set to C<WebTransaction> and transaction category is set to C<Uri>.

Returns the transaction's ID on success, else negative warning code or error code.

=head2 newrelic_transaction_set_name

 my $status = newrelic_transaction_set_name $tx, $name;

Sets the transaction name.

=head2 newrelic_transaction_set_request_url

 my $status = newrelic_transaction_set_request_url $tx, $url;

Sets the transaction URL.

=head2 newrelic_transaction_set_max_trace_segments

 my $status = newrelic_transaction_set_max_trace_segments $tx, $max;

Sets the maximum trace section for the transaction.

=head2 newrelic_transaction_set_category

 my $status = newrelic_transaction_set_category $tx, $category;

Sets the transaction category.

=head2 newrelic_transaction_set_type_web

 my $status = newrelic_transaction_set_type_web $tx;

Sets the transaction type to 'web'

=head2 newrelic_transaction_set_type_other

 my $status = newrelic_transaction_set_type_other $tx;

Sets the transaction type to 'other'

=head2 newrelic_transaction_add_attribute

 my $status = newrelic_transaction_add_attribute $tx, $key => $value;

Adds the given attribute (key/value pair) for the transaction.

=head2 newrelic_transaction_notice_error

 my $status = newrelic_transaction_notice_error $tx, $exception_type, $error_message, $stack_trace, $stack_frame_delimiter;

Identify an error that occurred during the transaction. The first identified
error is sent with each transaction.

=head2 newrelic_transaction_end

 my $status = newrelic_transaction_end $tx;

=head2 newrelic_record_metric

 my $status = newrelic_record_metric $key => $value;

Records the given metric (key/value pair).  The C<$value> should be a floating point.

=head2 newrelic_record_cpu_usage

 my $status = newrelic_record_cpu_usage $cpu_user_time_seconds, $cpu_usage_percent;

Records the CPU usage. C<$cpu_user_time_seconds> and C<$cpu_usage_percent> are floating point values.

=head2 newrelic_record_memory_usage

 my $status = newrelic_record_memory_usage $memory_megabytes;

Records the memory usage. C<$memory_megabytes> is a floating point value.

=head2 newrelic_segment_datastore_begin

 my $seg = newrelic_segment_datastore_begin $tx, $parent_seg, $name;

Begins a new generic segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).  C<$name> is a string.

=head2 newrelic_segment_generic_begin

 my $seg = newrelic_segment_generic_begin $tx, $parent_seg, $name;

Begins a new generic segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).  C<$name> is a string.

=cut

$ffi->attach( newrelic_transaction_begin                  => []                                                 => 'long' );
$ffi->attach( newrelic_transaction_set_name               => [ 'long', 'string' ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_request_url        => [ 'long', 'string' ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_max_trace_segments => [ 'long', 'int'    ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_category           => [ 'long', 'string' ]                               => 'int'  );
$ffi->attach( newrelic_transaction_set_type_web           => [ 'long' ]                                         => 'int'  );
$ffi->attach( newrelic_transaction_set_type_other         => [ 'long' ]                                         => 'int'  );
$ffi->attach( newrelic_transaction_add_attribute          => [ 'long', 'string', 'string' ]                     => 'int'  );
$ffi->attach( newrelic_transaction_notice_error           => [ 'long', 'string', 'string', 'string', 'string' ] => 'int'  );
$ffi->attach( newrelic_transaction_end                    => [ 'long' ]                                         => 'int'  );
$ffi->attach( newrelic_record_metric                      => [ 'string', 'double']                              => 'int'  );
$ffi->attach( newrelic_record_cpu_usage                   => [ 'double', 'double' ]                             => 'int'  );
$ffi->attach( newrelic_record_memory_usage                => [ 'double' ]                                       => 'int'  );
$ffi->attach( newrelic_segment_generic_begin              => [ 'long', 'long', 'string' ]                       => 'long' );

=head2 begin_datastore_segment

 my $seg = $agent->begin_datastore_segment($tx, $parent_seg, $table, $operation, $sql, $sql_trace_rollup_name);

Begins a new datastore segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).

=cut

# the OO version explicitly passes in newrelic_basic_literal_replacement_obfuscator, but this doesn't seem to
# do much, as that appears to be the default.  For the Procedural version we pass in NULL by default, but you
# can override with another symbol if you want.  Needs to be a C symbol though, not a Perl code ref.
$ffi->attach( newrelic_segment_datastore_begin => [ 'long', 'long', 'string', 'string', 'string', 'string', 'opaque' ] => 'long' );
         
=head2 newrelic_segment_external_begin

 my $seg = newrelic_segment_external_begin $tx, $parent_seg, $host, $name;

Begins a new external segment.  C<$parent_seg> is a parent segment id (C<undef> no parent).

=head2 newrelic_segment_end

 my $status = newrelic_segment_end $tx, $seg;

End the given segment.

=cut

$ffi->attach( newrelic_segment_external_begin => [ 'long', 'long', 'string', 'string' ] => 'long' );
$ffi->attach( newrelic_segment_end            => [ 'long', 'long' ] => 'int' );

our @EXPORT = grep /^newrelic_/, keys %NewRelic::Agent::FFI::Procedural::;

# TODO: embeded mode interface
# TODO: example for using newrelic_segment_datastore_begin with non default obfuscator

1;

=head1 SEE ALSO

=over 4

=item L<NewRelic::Agent::FFI>

=back

=cut

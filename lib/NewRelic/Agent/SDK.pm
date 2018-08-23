package NewRelic::Agent::SDK;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus;
use Alien::nragent;
use base qw( Exporter );

our @EXPORT = qw(
  newrelic_init newrelic_embed_collector newrelic_transaction_begin newrelic_transaction_set_name newrelic_transaction_set_request_url newrelic_transaction_set_max_trace_segments newrelic_transaction_set_category
  newrelic_transaction_set_type_web newrelic_transaction_set_type_other newrelic_transaction_add_attribute newrelic_transaction_notice_error newrelic_transaction_end newrelic_record_metric newrelic_record_cpu_usage
  newrelic_record_memory_usage newrelic_segment_generic_begin newrelic_segment_datastore_begin newrelic_segment_external_begin newrelic_segment_end
);

# ABSTRACT: Perl Agent for NewRelic APM
# VERSION

my $ffi = FFI::Platypus->new;
$ffi->lib(Alien::nragent->dynamic_libs);

=head1 FUNCTIONS

=head2 newrelic_init

 newrelic_init( $license_key, $app_name, $app_language, $app_language_version );

=cut

$ffi->attach( newrelic_init => [ 'string', 'string', 'string', 'string' ] => 'void' );

=head2 newrelic_embed_collector

 newrelic_embed_collector;

=cut

sub newrelic_embed_collector
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

=head2 newrelic_transaction_begin

 my $txn_id = newrelic_transaction_begin;

=cut

$ffi->attach( newrelic_transaction_begin => [] => 'long' );


=head2 newrelic_transaction_set_name

=head2 newrelic_transaction_set_request_url

=head2 newrelic_transaction_set_max_trace_segments

=head2 newrelic_transaction_set_category

=cut

$ffi->attach( newrelic_transaction_set_name               => [ 'long', 'string' ] => 'int' );
$ffi->attach( newrelic_transaction_set_request_url        => [ 'long', 'string' ] => 'int' );
$ffi->attach( newrelic_transaction_set_max_trace_segments => [ 'long', 'int'    ] => 'int' );
$ffi->attach( newrelic_transaction_set_category           => [ 'long', 'string' ] => 'int' );

=head2 newrelic_transaction_set_type_web

=head2 newrelic_transaction_set_type_other

=cut

$ffi->attach( newrelic_transaction_set_type_web   => [ 'long' ] => 'int' );
$ffi->attach( newrelic_transaction_set_type_other => [ 'long' ] => 'int' );

=head2 newrelic_transaction_add_attribute

=cut

$ffi->attach( newrelic_transaction_add_attribute => [ 'long', 'string', 'string' ] => 'int' );

=head2 newrelic_transaction_notice_error

=cut

$ffi->attach( newrelic_transaction_notice_error => [ 'long', 'string', 'string', 'string', 'string' ] => 'int' );

=head2 newrelic_transaction_end

=head2 newrelic_record_metric

=head2 newrelic_record_cpu_usage

=head2 newrelic_record_memory_usage

=cut

$ffi->attach( newrelic_transaction_end     => [ 'long' ]             => 'int' );
$ffi->attach( newrelic_record_metric       => [ 'string', 'double']  => 'int' );
$ffi->attach( newrelic_record_cpu_usage    => [ 'double', 'double' ] => 'int' );
$ffi->attach( newrelic_record_memory_usage => [ 'double' ]           => 'int' );

=head2 newrelic_segment_generic_begin

=cut

$ffi->attach( newrelic_segment_generic_begin => [ 'long', 'long', 'string' ] => 'long' );

=head2 newrelic_segment_datastore_begin

=cut

$ffi->attach( newrelic_segment_datastore_begin => [ 'long', 'long', 'string', 'string', 'string', 'string', 'opaque' ] => 'long' );

=head2 newrelic_segment_external_begin

=cut

$ffi->attach( newrelic_segment_external_begin => [ 'long', 'long', 'string', 'string' ] => 'long' );

=head2 newrelic_segment_end

=cut

$ffi->attach( newrelic_segment_end => [ 'long', 'long' ] => 'int' );

1;


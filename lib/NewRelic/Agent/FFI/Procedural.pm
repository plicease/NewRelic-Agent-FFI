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

=cut

$ffi->attach( newrelic_transaction_begin => [] => 'long' );

1;

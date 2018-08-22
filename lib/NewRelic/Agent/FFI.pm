package NewRelic::Agent::FFI;

use strict;
use warnings;
use 5.008001;
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

sub get_license_key { shift->{license_key} }
sub get_app_name { shift->{app_name} }
sub get_app_language { shift->{app_language} }
sub get_app_language_version { shift->{app_language_version} }

1;

=head1 SYNOPSIS

 use NewRelic::Agent;
 
 my $agent = NewRelic:Agent->new(
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

=cut

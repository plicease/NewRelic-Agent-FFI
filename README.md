# NewRelic::Agent::FFI [![Build Status](https://secure.travis-ci.org/plicease/NewRelic-Agent-FFI.png)](http://travis-ci.org/plicease/NewRelic-Agent-FFI)

Perl Agent for NewRelic APM

# SYNOPSIS

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

# DESCRIPTION

This module provides bindings for the [NewRelic](https://docs.newrelic.com/docs/agents/agent-sdk/getting-started/new-relic-agent-sdk) Agent SDK.

It is a drop in replacement for [NewRelic::Agent](https://metacpan.org/pod/NewRelic::Agent) that is implemented using [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instead of XS and C++.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

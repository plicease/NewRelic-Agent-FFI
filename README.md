# NewRelic::Agent::FFI [![Build Status](https://secure.travis-ci.org/plicease/NewRelic-Agent-FFI.png)](http://travis-ci.org/plicease/NewRelic-Agent-FFI)

Perl Agent for NewRelic APM

# SYNOPSIS

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

# DESCRIPTION

This module provides bindings for the [NewRelic](https://docs.newrelic.com/docs/agents/agent-sdk/getting-started/new-relic-agent-sdk) Agent SDK.

It is a drop in replacement for [NewRelic::Agent](https://metacpan.org/pod/NewRelic::Agent) that is implemented using [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instead of XS and C++.  If you are writing
new code, then I highly recommend the procedural interface instead: [NewRelic::Agent::FFI::Procedural](https://metacpan.org/pod/NewRelic::Agent::FFI::Procedural).

Why use [NewRelic::Agent::FFI](https://metacpan.org/pod/NewRelic::Agent::FFI) module instead of [NewRelic::Agent](https://metacpan.org/pod/NewRelic::Agent)?

- Powerful [Alien](https://metacpan.org/pod/Alien) technology

    This module uses [Alien::nragent](https://metacpan.org/pod/Alien::nragent) to either download the NR agent or to use a locally installed copy.  The other module has
    [a serious bug which will break when the install files are removed](https://github.com/aanari/NewRelic-Agent/issues/2)!  You
    can choose the version of the NR SDK that you want to use instead of relying on the maintainer of [NewRelic::Agent](https://metacpan.org/pod/NewRelic::Agent) to do so.

- Possible license issues

    Related to the last point, the other module bundles the NR SDK, which may have legal risks (I am not a lawyer).  In the very least
    I think goes against the Open Source philosophy of CPAN.

- No C++ compiler required!

    Since this module is built with powerful FFI and Platypus technology, you don't need to build XS bindings for it.  The
    other module has its bindings written in C++, which is IMO unnecessary and doesn't add anything.

- Tests!

    The test suite for [NewRelic::Agent](https://metacpan.org/pod/NewRelic::Agent) is IMO insufficient to have confidence in it, especially if the SDK needs to be upgraded.
    This module comes with a number of tests that will at least make sure that the calls to NewRelic will not crash your application.
    The live test can even be configured (not on by default) to send data to NR so that you can be sure it works.

- Active Development

    At least as of this writing, this module is being actively developed.  The other module has a number of unanswered open issues,
    bugs and pull requests.

Why use the other module instead of this one?

- This module is newer

    The other module has been around for longer, and may have been used in production more.  Peoples will probably have noticed if it
    were broken by now.

# CONSTRUCTOR

## new

    my $agent = NewRelic::Agent::FFI->new(%options);

Instantiates a new NewRelic::Agent client object.  Options include:

- `license_key`

    A valid NewRelic license key for your account.

    This value is also automatically sourced from the `NEWRELIC_LICENSE_KEY` environment variable.

- `app_name`

    The name of your application.

    This value is also automatically sourced from the `NEWRELIC_APP_NAME` environment variable.

- `app_language`

    The language that your application is written in.

    This value defaults to `perl`, and can also be automatically sourced from the `NEWRELIC_APP_LANGUAGE` environment variable.

- `app_language_version`

    The version of the language that your application is written in.

    This value defaults to your perl version, and can also be automatically sourced from the `NEWRELIC_APP_LANGUAGE_VERSION` environment variable.

# METHODS

Methods noted below that return `$status` return 0 for success or non-zero for failure.  See the NR SDK documentation for error codes.

## embed\_collector

    $agent->embed_collector;

Embeds the collector agent for harvesting NewRelic data. This should be called before `init`, if the agent is being used in Embedded mode and not Daemon mode.

## init

    my $status = $agent->init;

Initialize the connection to NewRelic.

## begin\_transaction

    my $tx = $agent->begin_transaction;

Identifies the beginning of a transaction, which is a timed operation consisting of multiple segments. By default, transaction type is set to `WebTransaction` and transaction category is set to `Uri`.

Returns the transaction's ID on success, else negative warning code or error code.

## set\_transaction\_name

    my $status = $agent->set_transaction_name($tx, $name);

Sets the transaction name.

## set\_transaction\_request\_url

    my $status = $agent->set_transaction_request_url($tx, $url);

Sets the transaction URL.

## set\_transaction\_max\_trace\_segments

    my $status = $agent->set_transaction_max_trace_segments($tx, $max);

Sets the maximum trace section for the transaction.

## set\_transaction\_category

    my $status = $agent->set_transaction_category($tx, $category);

Sets the transaction category.

## set\_transaction\_type\_web

    my $status = $agent->set_transaction_type_web($tx);

Sets the transaction type to 'web'

## set\_transaction\_type\_other

    my $status = $agent->set_transaction_type_other($tx);

Sets the transaction type to 'other'

## add\_transaction\_attribute

    my $status = $agent->add_transaction_attribute($tx, $key => $value);

Adds the given attribute (key/value pair) for the transaction.

## notice\_transaction\_error

    my $status = $agent->notice_transaction_error($tx, $exception_type, $error_message, $stack_trace, $stack_frame_delimiter);

Identify an error that occurred during the transaction. The first identified
error is sent with each transaction.

## end\_transaction

    my $status = $agent->end_transaction($tx);

## record\_metric

    my $status = $agent->record_metric($key => $value);

Records the given metric (key/value pair).  The `$value` should be a floating point.

## record\_cpu\_usage

    my $status = $agent->record_cpu_usage($cpu_user_time_seconds, $cpu_usage_percent);

Records the CPU usage. `$cpu_user_time_seconds` and `$cpu_usage_percent` are floating point values.

## record\_memory\_usage

    my $status = $agent->record_memory_usage($memory_megabytes);

Records the memory usage. `$memory_megabytes` is a floating point value.

## begin\_generic\_segment

    my $seg = $agent->begin_generic_segment($tx, $parent_seg, $name);

Begins a new generic segment.  `$parent_seg` is a parent segment id (`undef` no parent).  `$name` is a string.

## begin\_datastore\_segment

    my $seg = $agent->begin_datastore_segment($tx, $parent_seg, $table, $operation, $sql, $sql_trace_rollup_name);

Begins a new datastore segment.  `$parent_seg` is a parent segment id (`undef` no parent).

## begin\_external\_segment

    my $seg = $agent->begin_external_segment($tx, $parent_seg, $host, $name);

Begins a new external segment.  `$parent_seg` is a parent segment id (`undef` no parent).

## end\_segment

    my $status = $agent->end_segment($tx, $seg);

End the given segment.

## get\_license\_key

    my $key = $agent->get_license_key;

Get the license key.

## get\_app\_name

    my $name = $agent->get_app_name;

Get the application name.

## get\_app\_language

    my $lang = $agent->get_app_language;

Get the language name (usually `perl`).

## get\_app\_language\_version

    my $version = $agent->get_app_language_version;

Get the language version.

# SEE ALSO

- [NewRelic::Agent::FFI::Procedural](https://metacpan.org/pod/NewRelic::Agent::FFI::Procedural)

    Procedural interface, recommended over this one.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

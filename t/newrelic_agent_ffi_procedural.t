use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI::Procedural;

subtest 'export' => sub {

  imported_ok 'newrelic_init';
  
  note "also imported: $_" for @NewRelic::Agent::FFI::Procedural::EXPORT;
  
  ok(newrelic_message_handler, "address of newrelic_message_handler: @{[ newrelic_message_handler ]}");

};

subtest 'newrelic_segment_datastore_begin' => sub {

  skip_all 'TODO';

};

done_testing;

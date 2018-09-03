use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI::Procedural;

subtest 'export' => sub {

  imported_ok 'newrelic_init';
  
  note "also imported: $_" for @NewRelic::Agent::FFI::Procedural::EXPORT;

};

subtest 'newrelic_register_message_handler' => sub {

  skip_all 'TODO';

};

subtest 'init' => sub {

  skip_all 'TODO';

};

subtest 'newrelic_segment_datastore_begin' => sub {

  skip_all 'TODO';

};

done_testing;

require 'rake'
require 'rake/testtask'
require 'test/helper'

Rake::TestTask.new(:test_with_active_record) do |t|
  t.libs << SlimScrooge::ActiveRecordTest::AR_TEST_SUITE
  t.libs << SlimScrooge::ActiveRecordTest.connection
  t.test_files = SlimScrooge::ActiveRecordTest.test_files
  t.ruby_opts = ["-r #{File.join(File.dirname(__FILE__), 'test', 'active_record_setup')}"]
  t.verbose = true
end

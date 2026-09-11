# © 2026 aiaiaiai · aiaiaiai.org

require "rake/testtask"

Rake::TestTask.new(:test) do |task|
  task.libs << "lib"
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
end

desc "Check repository architecture invariants"
task :check do
  ruby "script/check_architecture.rb"
end

task default: %i[test check]

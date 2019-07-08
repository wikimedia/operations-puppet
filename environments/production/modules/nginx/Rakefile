require 'bundler/setup'
require 'rake'
require 'rspec/core/rake_task'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

# To please Jenkins
# https://github.com/rodjek/puppet-lint/issues/361
PuppetLint.configuration.relative = true

RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/*/*_rspec.rb'
end

task :default => [:help]

desc 'Run all build/tests commands (CI entry point)'
task :test => [
    :syntax,
    :lint,
]

task :help do
    system "rake -T"
end

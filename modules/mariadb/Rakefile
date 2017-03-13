require 'bundler/setup'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

# To please Jenkins
# https://github.com/rodjek/puppet-lint/issues/361
PuppetLint.configuration.relative = true

task :default => [:help]

desc 'Run all build/tests commands (CI entry point)'
task :test => [
    :syntax,
    :lint,
]

task :help do
    system "rake -T"
end

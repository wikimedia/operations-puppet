require 'rake'
require 'rspec/core/rake_task'

task :default => :spec

RSpec::Core::RakeTask.new( :spec ) do |task|
  task.rspec_opts = %w[ --color --format doc ]
  task.pattern    = 'spec/*/*_spec.rb'
end


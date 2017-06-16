# This rakefile is meant to run linters and tests
# tailored to a specific changeset.
# You will need 'bundler' to install dependencies:
#
#  $ apt-get install bundler
#  $ bundle install
#
# Then run all the tests, in parallel, that are pertinent to the current changeset
#
#   $ bundle exec rake test
#
# If you just want to check which tests would be ran, run
#
#   $ bundle exec rake debug
#
# Based on the contents of the change, this rakefile will define and run
# all or just some of the following tests:
#
# * puppet_lint - runs puppet lint on the changed puppet files
# * typos - checks the changed files against a predefined list of typos defined
#            in ./typos
# * syntax - run syntax checks for puppet files, hiera files, and templates
#            changed in the current changeset
# * rubocop - run rubocop style checks on ruby files changed in this changeset
# * spec - run the spec tests on the modules where files are changed, or whose
#           tests depend on modules that have been modified.
# * tox - run the tox tests if needed.
#
require 'git'
require 'set'
require 'rake'
require 'rake/tasklib'
require 'shellwords'

# Needed by docs
require 'puppet-strings/tasks/generate'
$LOAD_PATH.unshift File.expand_path('.')
require 'rake_modules/taskgen'

t = TaskGen.new('.')

multitask :parallel => t.tasks
desc 'Run all actual tests in parallel for changes in HEAD'
task :test => [:parallel, :wmf_styleguide_delta]

# Show what we would run
task :debug do
  puts "Tasks that would be run: "
  puts t.tasks
end

# Global tasks. Only the ones deemed useful are added here.
namespace :global do
  desc "Build documentation"
  task :doc do
    Rake::Task['strings:generate'].invoke(
      '**/*.pp **/*.rb',  # patterns
      'false', # debug
      'false', # backtrace
      'rdoc',  # markup format
    )
  end

  spec_failed = []
  spec_tasks = []
  namespace :spec do
    FileList['modules/*/spec'].each do |path|
      next unless path.match('modules/(.+)/')
      module_name = Regexp.last_match(1)
      task module_name do
        spec_result = system("cd 'modules/#{module_name}' && rake spec")
        spec_failed << module_name unless spec_result
      end
      spec_tasks << "spec:#{module_name}"
    end
  end
  desc "Run all spec tests found in modules"
  multitask :spec => spec_tasks do
    raise "Modules that failed to pass the spec tests: #{spec_failed.join ', '}" unless spec_failed.empty?
  end

  desc 'Run the wmf style guide check on all files, or on a single module (with module=<module-name>)'
  task :wmf_style do
    if ENV['module']
      pattern = "modules/#{ENV['module']}/**/*.pp"
    else
      pattern = '**/*.pp'
    end

    t.setup_wmf_lint_check
    linter = PuppetLint.new
    FileList[pattern].to_a.each do |puppet_file|
      linter.file = puppet_file
      linter.run
      next if linter.problems.empty?

      if ENV.key?('JENKINS_URL')
          t.print_wmf_style_violations linter.problems, nil, '%{path}:%{line}:%{check}:%{KIND}:%{message}'
      else
          t.print_wmf_style_violations linter.problems
      end
    end
  end
end

desc 'Show the help'
task :help do
  puts "Puppet helper for operations/puppet.git

Welcome #{ENV['USER']} to WMFs wonderful rake helper to play with puppet.

---[Command line options]----------------------------------------------
`rake -T` : list available tasks
`rake -P` : shows tasks dependencies

---[Available rake tasks]----------------------------------------------"

  # Show our tasks list.
  system "rake -T"

  puts "-----------------------------------------------------------------------"
end

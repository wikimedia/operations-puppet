# This rakefile is meant to run linters and tests.
#
# You will need 'bundler' to install dependencies:
#
#  $ apt-get install bundler
#  $ bundle install
#
# Then run the linter using rake (a ruby build helper) inside the env set by
# bundler:
#
#   $ bundle exec rake puppetlint
#
# puppet-lint doc is at https://github.com/rodjek/puppet-lint
#
#
# Another target is spec, which runs unit/integration tests. You will need some
# more gems installed using bundler:
#
#   $ bundle install
#   $ bundle exec rake spec
#
# Continuous integration invokes 'bundle exec rake test'.

require 'bundler/setup'
require 'git'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-strings/tasks/generate'
require 'puppet-syntax/tasks/puppet-syntax'
require 'rubocop/rake_task'
require 'rake/testtask'

# site.pp still uses an import statement for realm.pp (T154915)
PuppetSyntax.fail_on_deprecation_notices = false

if Puppet.version.to_f < 4.0
    PuppetSyntax.exclude_paths = [
        'modules/stdlib/types/*.pp',
        'modules/stdlib/types/compat/*.pp',
        'modules/stdlib/spec/fixtures/test/manifests/*.pp',
    ]
end

# Find files modified in HEAD
def git_changed_in_head(file_exts=[])
    g = Git.open('.')
    diff = g.diff('HEAD^')
    files = diff.name_status.select { |_, status| 'ACM'.include? status}.keys

    if file_exts.empty?
        files
    else
        files.select { |fname| fname.end_with?(*file_exts) }
    end
end

namespace :syntax do
    desc 'Syntax check Puppet manifests against HEAD'
    task :manifests_head do
        Puppet::Util::Log.newdestination(:console)
        files = git_changed_in_head ['.pp']
        files << 'manifests/site.pp'

        # XXX This is copy pasted from the puppet-syntax rake task. It does not
        # support injecting a specific list of files but always uses:
        #   FileList['**/*.pp']
        c = PuppetSyntax::Manifests.new
        output, has_errors = c.check(files)
        Puppet::Util::Log.close_all
        fail if has_errors || (output.any? && PuppetSyntax.fail_on_deprecation_notices)
    end

    desc 'Syntax checks against HEAD'
    task :head => [
        'syntax:manifests_head',
        'syntax:hiera',
        'syntax:templates',
    ]

end

RuboCop::RakeTask.new(:rubocop)

# Remane and customize puppet-lint built-in task
Rake::Task[:lint].clear
PuppetLint::RakeTask.new :puppetlint do |config|
    config.fail_on_warnings = true  # be strict
    config.log_format = '%{path}:%{line} %{KIND} %{message} (%{check})'
end
PuppetLint::RakeTask.new :puppetlint_head do |config|
    config.fail_on_warnings = true  # be strict
    config.log_format = '%{path}:%{line} %{KIND} %{message} (%{check})'
    config.pattern = git_changed_in_head ['.pp']
end


task :default => [:help]

desc 'Run all build/tests commands (CI entry point)'
task test: [:lint_head]

desc 'Run all linting commands'
task lint: [:rubocop, :syntax, :puppetlint]

desc 'Run all linting commands against HEAD'
task lint_head: [:rubocop, :"syntax:head", :puppetlint_head]


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
puts "
Examples:

Validate syntax for all puppet manifests:
  rake validate

Validate manifests/nfs.pp and manifests/apaches.pp
  rake \"validate[manifests/nfs.pp manifests/apaches.pp]\"

Run puppet-lint style checker:
  rake puppetlint
"

end

desc "Build documentation"
task :doc do
    Rake::Task['strings:generate'].invoke(
        '**/*.pp **/*.rb',  # patterns
        'false', # debug
        'false', # backtrace
        'rdoc',  # markup format
    )
end

def spec_modules
    module_names = []
    FileList['modules/*/spec'].each do |m|
        module_names << m.match('modules/(.+)/')[1]
    end
    module_names
end

namespace :spec do
    spec_modules.each do |module_name|
        desc "Run spec for module #{module_name}"
        task module_name do
            puts '-' * 80
            puts "Running rspec tests for module #{module_name}"
            puts '-' * 80
            spec_result = system("cd 'modules/#{module_name}' && rake spec")
            raise "Module #{module_name} failed to pass spec" if !spec_result
        end
    end
end

desc "Run spec tests found in modules"
task :spec do

    # Hold a list of modules not passing tests.
    failed_modules = []
    ignored_modules = ['mysql', 'osm', 'postgresql', 'puppetdbquery', 'stdlib', 'wdqs']

    # Invoke rake whenever a module has a Rakefile.
    spec_modules.each do |module_name|
        next if ignored_modules.include? module_name
        begin
            Rake::Task["spec:#{module_name}"].invoke
        rescue
            failed_modules << module_name  # recording
        end
        puts "\n"
    end

    puts '-' * 80
    puts 'Finished running tests for all modules'
    puts '-' * 80

    unless failed_modules.empty?
        puts "\nThe following modules are NOT passing tests:\n"
        puts '- ' + failed_modules * "\n- "
        puts
        raise "Some modules had failures, sorry."
    end
end

desc "Generates ctags"
task :tags do
    puts "Generating ctags file.."
    system('ctags -R .')
    puts "Done"
    puts
    puts "See https://github.com/majutsushi/tagbar/wiki#puppet for vim"
    puts "integration with the vim tagbar plugin."
end

# lint
# amass profit
# donate!

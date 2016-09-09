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
# more gems installed:
#
#   $ sudo gem install puppet rspec puppetlabs_spec_helper
#
# Then:
#
#   $ rake spec
#
# Continuous integration invokes 'bundle exec rake test'.

require 'bundler/setup'
require 'git'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-strings/tasks/generate'
require 'rubocop/rake_task'

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

# Only care about color when using a tty.
if Rake.application.tty_output?
    # Since we are going to use puppet internal stuff, we might as
    # well attempt to reuse their colorization utility. Note the utility class
    # is not available in older puppet versions.
    begin
        require'puppet/util/colors'
        include Puppet::Util::Colors
    rescue LoadError
        puts "Cant load puppet/util/colors .. no color for you!"
    end
end

unless respond_to? :console_color
    # Define our own colorization method that simply outputs the message.
    def console_color(_level, message)
        message
    end
end

task :default => [:help]

desc 'Run all build/tests commands (CI entry point)'
task test: [:lint_head]

desc 'Run all linting commands'
task lint: [:rubocop, :puppetlint]

desc 'Run all linting commands against HEAD'
task lint_head: [:rubocop, :puppetlint_head]


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
        '**/*.pp',  # patterns
        'false',    # debug
        'false',    # backtrace
        'rdoc',     # markup format
    )
end

desc "Validate puppet syntax (default: manifests/site.pp)"
task :validate, [:files ] do |_t, args|

    success = true

    if args.files
        puts console_color(:info, "Validating " + args.files.inspect)
        ok = puppet_parser_validate args.files
    else
        ok = puppet_parser_validate 'manifests/site.pp'
        success &&= ok

        Dir.glob("modules/*").each do |dir|
            puts console_color(:info, "Validating manifests in '#{dir}'")
            ok = puppet_parser_validate Dir.glob("#{dir}/**/*.pp")
            success &&= ok
        end
    end

    if success
        puts "[OK] " + console_color(:info,  "files looks fine!")
    else
        raise console_color(:alert, "puppet failed to validate files (exit: #{res.exitstatus}")
    end
end

# Validate manifests passed as an array of filenames.
def puppet_parser_validate(*manifests)
    manifests = manifests.join(' ')
    sh "puppet parser validate #{manifests}"
end

desc "Run spec tests found in modules"
task :spec do

    # Hold a list of modules not passing tests.
    failed_modules = []

    # Invoke rake whenever a module has a Rakefile.
    FileList["modules/*/Rakefile"].each do |rakefile|

        module_name = rakefile.match('modules/(.+)/')[1]

        if !run_module_spec(module_name)
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

# Wrapper to run rspec in a module.
def run_module_spec(module_name)

    puts '-' * 80
    puts "Running rspec tests for module #{module_name}"
    puts '-' * 80

    Dir.chdir("modules/#{module_name}") do
        # The following is a customized replacement for 'spec_prep'.
        # We do not want to use upstream modules which are usually installed
        # using `rake spec_prep`, instead we symlink to our own modules.
        directory_name = "spec/fixtures"
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
        link_name = "spec/fixtures/modules"
        system("ln -s ../../../../modules #{link_name}") unless File.exists?(link_name)

        # We also need to create an empty site.pp file in the manifests dir.
        directory_name = "spec/fixtures/manifests"
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
        site_file_name = "spec/fixtures/manifests/site.pp"
        system("touch #{site_file_name}") unless File.exists?(site_file_name)

        puts "Invoking tests on module #{module_name}"
        system('rake spec_standalone')
    end
end


# lint
# amass profit
# donate!

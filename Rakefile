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

require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax'
require 'puppet-syntax/tasks/puppet-syntax'
require 'rubocop/rake_task'
# Needed by docs
require 'puppet-strings/tasks/generate'

# Monkey-patch PuppetSyntax and its rake task
module PuppetSyntax
  @manifests_paths = ["**/*.pp"]
  @templates_paths = ["**/*.erb"]
  class << self
    attr_accessor :manifests_paths, :templates_paths
  end
end

class PuppetSyntax::RakeTask
  def filelist_manifests
    filelist(PuppetSyntax.manifests_paths)
  end

  def filelist_templates
    filelist(PuppetSyntax.templates_paths)
  end
end

# Fix ruby-git deficiencies. TODO: move to rugged instead?
module Git
  class Lib
    def symbolic_ref(ref)
      command('symbolic-ref', ref)
    end
  end
  class Base
    def detached_head?
        lib.symbolic_ref('HEAD')
        false
      rescue Git::GitExecuteError
        true
    end
  end
end

class SpecDependencies
  # Finds all specs to run based on the changed modules.

  def initialize
    @deps = {}
    FileList["modules/*/.fixtures.yml"].each do |file|
      module_name = module_from_filename(file)
      symlinks = YAML.safe_load(File.open(file))['fixtures']['symlinks'].keys.select{ |x| x != module_name }
      symlinks.each do |dependency|
        @deps[dependency] ||= []
        @deps[dependency] << module_name
      end
    end
  end

  def specs_to_run(filelist)
    specs = Set.new
    modules = modules_modified(filelist)
    return [] if !modules
    modules.each do |mod|
      next unless Dir.exists?("modules/#{mod}/spec")
      specs.add(mod)
      if @deps.include?mod
        @deps[mod].each{ |m| specs.add(m) }
      end
    end
    specs.to_a
  end

  private

  def modules_modified(filelist)
    modules = Set.new
    filelist.each do |file|
      module_name = module_from_filename(file)

      modules.add(module_name) if module_name
    end
    modules.to_a
  end

  def module_from_filename(name)
    if %r{modules/([^/]+)} =~ name
      Regexp.last_match(1)
    else
      nil
    end
  end
end

class TaskGen < ::Rake::TaskLib
  attr_accessor :tasks, :failed_specs

  def initialize(path)
    @tasks_categories = [
      :puppet_lint,
      :typos,
      :syntax,
      :rubocop,
      :spec,
      :tox
    ]
    @git = Git.open(path)
    @changed_files = git_changed_in_head
    @tasks = setup_tasks
    @failed_specs = []
  end

  private

  def git_changed_files
    # Files changed in puppet, including renames
    old = []
    new = []
    diffs = @git.diff('HEAD^')
    diffs.each do |diff|
      name_status = diffs.name_status[diff.path]
      case name_status
      when 'A'
        new << diff.path
      when 'C', 'M'
        new << diff.path
        old << diff.path
      when 'D'
        old << diff.path
      when /R\d+/
        old << diff.path
        regex = Regexp.new "^diff --git a/#{Regexp.escape(diff.path)} b/(.+)"
        if diff.patch =~ regex
          new << Regexp.last_match[1]
        end
      end
    end
    {old: old, new: new}
  end

  def git_changed_in_head
    git_changed_files[:new]
  end

  def setup_tasks
    tasks = []
    @tasks_categories.each do |cat|
      method_name = "setup_#{cat}"
      tasks.concat send(method_name)
    end
    setup_wmf_styleguide_delta
    tasks
  end

  def puppet_changed_files(files=@changed_files)
    files.select{ |x| File.fnmatch("*.pp", x) }
  end

  def filter_files_by(*globs)
    changed = FileList[@changed_files]
    changed.exclude(*PuppetSyntax.exclude_paths).select do |file|
      # If at least one glob pattern matches, the file is included.
      !globs.select{ |glob| File.fnmatch(glob, file)}.empty?
    end
  end

  def linter_problems(files)
      linter = PuppetLint.new
      puppet_changed_files(files).each do |puppet_file|
        next unless File.file?(puppet_file)
        linter.file = puppet_file
        linter.run
      end
      linter.problems
  end

  def setup_wmf_lint_check
    PuppetLint.configuration.checks.each do |check|
      if check == :wmf_styleguide
        PuppetLint.configuration.send('enable_wmf_styleguide')
      else
        PuppetLint.configuration.send("disable_#{check}")
      end
    end
  end

  def print_wmf_style_violations(problems, other=nil)
    other ||= {}
    events = problems.select do |p|
      other.select { |x| x[:message] == p[:message] && x[:path] == p[:path] }.empty?
    end
    events.each do |p|
      puts "#{p[:path]}:#{p[:line]} #{p[:message]}"
    end
    puts "Nothing found" if events.length.zero?
  end

  def setup_puppet_lint
    # Sets up a standard puppet-lint task
    changed = puppet_changed_files
    return [] if changed.empty?
    # Reset puppet-lint tasks, define a new one
    Rake::Task[:lint].clear
    PuppetLint.configuration.send('disable_wmf_styleguide')
    PuppetLint::RakeTask.new :puppet_lint do |config|
      config.fail_on_warnings = true  # be strict
      config.log_format = '%{path}:%{line} %{KIND} %{message} (%{check})'
      config.pattern = changed
    end
    [:puppet_lint]
  end

  def setup_wmf_styleguide_delta
    changed = git_changed_files
    if puppet_changed_files(changed.values.flatten.uniq).empty?
      task :wmf_styleguide do
        puts "wmf-style: no files to check"
      end
      task :wmf_styleguide_delta => [:wmf_styleguide]
    else
      desc 'Check wmf styleguide violations in the current commit'
      task :wmf_styleguide do
        setup_wmf_lint_check
        problems = linter_problems changed[:new]
        print_wmf_style_violations(problems)
        abort("wmf-styleguide: NOT OK")
      end

      desc 'Check regressions for the wmf style guide'
      task :wmf_styleguide_delta do
        puts '---> wmf_style lint'
        setup_wmf_lint_check
        if @git.diff('HEAD').size > 0
          puts "Will NOT run the task as you have uncommitted changes that would be lost"
          next
        end

        # Only enable the wmf_styleguide
        new_problems = linter_problems changed[:new]
        # Check out temporary branch, and re-run the check to the previous commit
        alphabet = [*('a'..'z')]
        random_branch_name = 'wmf_styleguide_' + (0..6).map { alphabet[rand(26)]}.join
        old_problems = nil
        # If we're in a detached head situation, assume it's ok to just roll back
        if @git.detached_head?
          sha1 = @git.revparse('HEAD')
          @git.reset_hard('HEAD^')
          old_problems = linter_problems changed [:old]
          @git.checkout(sha1)
        else
          @git.branch(random_branch_name).in_branch do
            @git.reset_hard('HEAD^')
            old_problems = linter_problems changed[:old]
            false
          end
          @git.branch(random_branch_name).delete
        end
        delta = new_problems.length - old_problems.length
        puts "wmf-style: total violations delta #{delta}"
        puts "NEW violations:"
        print_wmf_style_violations(new_problems, old_problems)
        puts "Resolved violations:"
        print_wmf_style_violations(old_problems, new_problems)
        puts '---> end wmf_style lint'
        abort if delta > 0
      end
    end
  end

  def setup_typos
    return [] if @changed_files.empty?
    # Exclude the typos file itself
    shell_files = Shellwords.join(@changed_files - ['typos'])
    # If only typos was modified, bail out immediately
    return [] if shell_files.empty?
    desc "Check common typos from /typos"
    task :typos do
      system("git grep -I -n -P -f typos -- #{shell_files}")
      case $CHILD_STATUS.exitstatus
      when 0
        fail "Typo found!"
      when 1
        puts "No typo found."
      else
        fail "Some error occured"
      end
    end
    [:typos]
  end

  def setup_syntax
    # Reset puppet-syntax tasks, define a new one
    Rake::Task[:syntax].clear

    # site.pp still uses an import statement for realm.pp (T154915)
    # We can think of activating this once we've moved to the future parser
    PuppetSyntax.fail_on_deprecation_notices = false
    if Puppet.version.to_f < 4.0
      PuppetSyntax.exclude_paths = [
        'modules/stdlib/types/*.pp',
        'modules/stdlib/types/compat/*.pp',
        'modules/stdlib/spec/fixtures/test/manifests/*.pp',
      ]
      PuppetSyntax.future_parser = true
    end
    # Set up filelists
    PuppetSyntax.manifests_paths = puppet_changed_files
    PuppetSyntax.templates_paths = filter_files_by("**/templates/**/*.erb", "**/templates/**/*.epp")
    PuppetSyntax.hieradata_paths = filter_files_by("hieradata/**/*.yaml", "conftool-data/**/*.yaml")
    tasks = []
    unless PuppetSyntax.manifests_paths.empty?
      tasks << 'syntax:manifests'
    end
    unless PuppetSyntax.templates_paths.empty?
      tasks << 'syntax:templates'
    end
    unless PuppetSyntax.hieradata_paths.empty?
      tasks << 'syntax:hiera'
    end
    return tasks if tasks.empty?
    # Now re-set up the jobs by instantiating the class
    PuppetSyntax::RakeTask.new
    # The jobs we select here need to be run in sequence for some thread-safety reasons
    task :syntax_all => tasks
    [:syntax_all]
  end

  def setup_rubocop
    # Files that require a full tree compilation.
    # If the gemfile changed, we might have updated rubocop.
    # Err on the side of caution and scan all files in that case.
    # Also, if the rubocop exceptions changed, check the whole tree
    global_files = ['Gemfile', '.rubocop.todo.yml']
    ruby_files = filter_files_by("**/*.rb", "**/Rakefile", 'Rakefile', 'Gemfile', '**/.rubocop.todo.yml')
    return [] if ruby_files.empty?
    rubocop_task = RuboCop::RakeTask.new(:rubocop)
    if @changed_files.select{ |f| global_files.include?f }.empty?
      rubocop_task.patterns = ruby_files
    end

    [:rubocop]
  end

  def setup_spec
    # Modules known not to pass tests
    ignored_modules = ['mysql', 'osm', 'puppetdbquery', 'stdlib', 'wdqs', 'tilerator', 'wmflib']
    deps = SpecDependencies.new
    spec_modules = deps.specs_to_run(@changed_files).select do |m|
      !ignored_modules.include?(m)
    end
    return [] if spec_modules.empty?

    namespace :spec do
      spec_modules.each do |module_name|
        desc "Run spec for module #{module_name}"
        task module_name do
          puts "---> spec:#{module_name}"
          spec_result = system("cd 'modules/#{module_name}' && rake spec")
          if !spec_result
            @failed_specs << module_name
          end
          puts "---> spec:#{module_name}"
        end
      end
    end
    desc "Run spec tests found in modules"
    multitask :spec => spec_modules.map{ |m| "spec:#{m}" } do
      raise "Modules that failed to pass the spec tests: #{@failed_specs.join ', '}" if !@failed_specs.empty?
    end
    [:spec]
  end

  def setup_tox
    tasks = []
    namespace :tox do
      if @changed_files.include?('tox.ini')
        desc 'Refresh the tox environment'
        task :update do
          raise "Running tox failed" unless system('tox -r')
        end
        tasks << 'tox:update'
      else
        if @changed_files.include?('admin/modules/data/data.yaml')
          desc 'Run tox for the admin data file'
          task :admin do
            res = system('tox -e testenv')
            raise "Tox tests for admin/data/data.yaml failed!" if !res
          end
          tasks << 'tox:admin'
        end
        webperf_files = filter_files_by("modules/webperf/files/*.*")
        unless webperf_files.empty?
          desc 'Run tox for webperf'
          task :webperf do
            res = system("tox -e webperf")
            raise 'Tests for webperf failed!' if !res
          end
          tasks << 'tox:webperf'
        end
        tox_files = filter_files_by("*.py")
        unless tox_files.empty?
          desc 'Run flake8 on python files via tox'
          task :flake8 do
            shell_tox_files = Shellwords.join(tox_files)
            raise "Flake8 failed" unless system("tox -e pep8 #{shell_tox_files}")
          end
          tasks << 'tox:flake8'
        end
        desc 'Check commit message'
        task :commit_message do
          raise 'Invalid commit message' unless system("tox -e commit-message")
        end
        tasks << 'tox:commit_message'
      end
    end

    desc 'Run all the tox-related tasks'
    task :tox => tasks
    [:tox]
  end
end

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
      desc "Run spec for module #{module_name}"
      task module_name do
        spec_result = system("cd 'modules/#{module_name}' && rake spec")
        spec_failed << module_name if !spec_result
      end
      spec_tasks << "spec:#{module_name}"
    end
  end
  desc "Run all spec tests found in modules"
  multitask :spec => spec_tasks do
    raise "Modules that failed to pass the spec tests: #{spec_failed.join ', '}" unless spec_failed.empty?
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

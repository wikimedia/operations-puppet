require 'fileutils'
require 'git'
require 'set'
require 'json'
require 'parallel_tests'
require 'yaml'
require 'rake'
require 'rake/tasklib'
require 'shellwords'

require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax'
require 'puppet-syntax/tasks/puppet-syntax'
require 'rubocop/rake_task'

require 'rake_modules/monkey_patch'
require 'rake_modules/git'
require 'rake_modules/specdeps'
require 'rake_modules/tasks/spdx'

class TaskGen < ::Rake::TaskLib
  attr_accessor :tasks, :failed_specs

  def initialize(path)
    @tasks_categories = [
      :puppet_lint,
      :typos,
      :syntax,
      :json_syntax,
      :rubocop,
      :common_yaml,
      :hiera_defaults,
      :shellcheck,
      :python_extensions,
      :spec,
      :tox,
      :per_module_tox,
    ]
    @git = GitOps.new(path)
    @changed_files_with_vendored = @git.changes_in_head
    vendor_paths = ['vendor/**/*', 'vendor_modules/**/*', 'core_modules/**/*']
    @changed_files = FileList[@changed_files_with_vendored].exclude(vendor_paths).to_a
    PuppetSyntax.exclude_paths = vendor_paths
    @tasks = setup_tasks + setup_spdx(@git)
    @failed_specs = []
  end

  def setup_wmf_lint_check
    # Sets up puppet-lint to only check for the wmf style guide
    PuppetLint.configuration.checks.each do |check|
      if check == :wmf_styleguide
        PuppetLint.configuration.send('enable_wmf_styleguide')
      else
        PuppetLint.configuration.send("disable_#{check}")
      end
    end
  end

  def print_wmf_style_violations(problems, other = nil, format = '%{path}:%{line} %{message}')
    # Prints the wmf style violations
    other ||= {}
    events = problems.select do |p|
      other.select { |x| x[:message] == p[:message] && x[:path] == p[:path] }.empty?
    end
    events.each do |p|
      p[:KIND] = p[:kind].to_s.upcase
      puts format(format, p).red
    end
    puts "Nothing found".green if events.length.zero?
  end

  private

  def setup_tasks
    tasks = []
    @tasks_categories.each do |cat|
      method_name = "setup_#{cat}"
      tasks.concat send(method_name)
    end
    setup_wmf_styleguide_delta
    tasks
  end

  def sort_python_files(files, default = :py2)
    py_files = { py2: [], py3: [] }
    files_unknown_version = []
    deps = SpecDependencies.new
    have_own_tox = deps.files_with_own_tox(files)

    files.reject{ |file| have_own_tox.include?(file) }.each do |file|
      next if File.zero?(file)
      # skip files copied from upstream
      next if file.end_with?('.original.py')
      # skip scripts in user home dirs
      next if file.start_with?('modules/admin/files/home')
      shebang = File.open(file) {|f| f.readline}
      match = shebang.match(/#!.*(?:python|pytest\-)(\d?)/)
      if !match || !match.captures
        files_unknown_version << file
      # If the shebang has no version, it's calling the 'python' binary which is python2
      elsif match.captures[0] == '2' || match.captures[0] == ''
        py_files[:py2] << file
      elsif match.captures[0] == '3'
        py_files[:py3] << file
      else
        # might be more sensible to fail here?
        files_unknown_version << file
      end
    end
    puts "python2 files: #{py_files[:py2].length}".green unless py_files[:py2].empty?
    puts "python3 files: #{py_files[:py3].length}".green unless py_files[:py3].empty?
    puts "python files without a version (assumed #{default}): #{files_unknown_version.length}".yellow unless files_unknown_version.empty?
    py_files[default] += files_unknown_version
    py_files
  end

  def puppet_changed_files(files = @changed_files)
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
    problems = []
    linter = PuppetLint.new
    puppet_changed_files(files).each do |puppet_file|
      next unless File.file?(puppet_file)
      linter.file = puppet_file
      linter.run
      problems.concat(linter.problems)
    end
    problems.reject{ |p| p[:kind] == :ignored }
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
      config.log_format = '%{path}:%{line} %{KIND} %{message} (%{check})'.red
      config.pattern = changed
    end
    [:puppet_lint]
  end

  def setup_json_syntax
    # These files must be valid JSON
    json_globs = [
      '**/*.json',
      'modules/profile/files/conftool/json-schema/**/*.schema',
    ]
    changed = filter_files_by(*json_globs)
    return [] if changed.empty?
    desc 'Check files for valid JSON syntax'
    failures = false
    task :json_syntax do
      changed.each do |fn|
        begin
          JSON.parse(File.open(fn).read)
        rescue JSON::ParserError => e
          puts "Error parsing #{fn}".red
          puts e.message
          failures = true
        end
      end

      abort("JSON syntax: FAILED".red) if failures
      puts "JSON syntax: OK".green
    end
    [:json_syntax]
  end

  def setup_wmf_styleguide_delta
    if puppet_changed_files(@git.changes.values.flatten.uniq).empty?
      task :wmf_styleguide do
        puts "wmf-style: no files to check"
      end
      task :wmf_styleguide_delta => [:wmf_styleguide]
    else
      desc 'Check wmf styleguide violations in the current commit'
      task :wmf_styleguide do
        setup_wmf_lint_check
        problems = linter_problems @git.changes_in_head
        print_wmf_style_violations(problems)
        abort("wmf-styleguide: NOT OK".red)
      end

      desc 'Check regressions for the wmf style guide'
      task :wmf_styleguide_delta do
        puts '---> wmf_style lint'
        setup_wmf_lint_check
        if @git.uncommitted_changes?
          puts "Will NOT run the task as you have uncommitted changes that would be lost"
          next
        end
        # Only enable the wmf_styleguide
        new_problems = linter_problems @git.changes_in_head
        old_problems = nil
        @git.exec_in_rewind do
          old_problems = linter_problems @git.changed_files_in_last
        end
        delta = new_problems.length - old_problems.length
        puts "wmf-style: total violations delta #{delta}"
        puts "NEW violations:"
        print_wmf_style_violations(new_problems, old_problems)
        puts "Resolved violations:"
        print_wmf_style_violations(old_problems, new_problems)
        puts '---> end wmf_style lint'
        abort if delta > 0 # rubocop:disable Style/NumericPredicate
      end
    end
  end

  def setup_typos
    return [] if @changed_files.empty?
    excluded_files = [
      'typos',  # The typos file itself
      'hieradata/common/certificates.yaml',  # Houses domain typos
      'modules/ncredir/files/nc_redirects.dat'  # Houses domain typos
    ]
    shell_files = Shellwords.join(@changed_files - excluded_files)
    # If only typos was modified, bail out immediately
    return [] if shell_files.empty?
    desc "Check common typos from /typos"
    task :typos do
      system("git grep -I -n -P -f typos -- #{shell_files}")
      case $CHILD_STATUS.exitstatus
      when 0
        fail "Typo found!".red
      when 1
        puts "No typo found.".green
      else
        fail "Some error occurred".red
      end
    end
    [:typos]
  end

  def setup_syntax
    # Reset puppet-syntax tasks, define a new one
    Rake::Task[:syntax].clear
    namespace :syntax do
      Rake::Task[:manifests].clear
      Rake::Task[:hiera].clear
      Rake::Task[:templates].clear
    end
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
    PuppetSyntax.templates_paths = filter_files_by("**/templates/**.erb", "**/templates/**.epp")
    PuppetSyntax.hieradata_paths = filter_files_by("hieradata/**.yaml", "conftool-data/**.yaml")
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
    # .ruby-version is for rbenv but is also used by rubocop to override the
    # ruby version to use when parsing files (T250538).
    global_files = ['Gemfile', '.rubocop.todo.yml', '.ruby-version']
    ruby_files = filter_files_by("**/*.rb", "**/Rakefile", 'Puppetfile', 'Rakefile', 'Gemfile', '**/Vagrantfile', '**/.rubocop.todo.yml', '.ruby-version')
    return [] if ruby_files.empty?
    RuboCop::RakeTask.new(:rubocop) do |r|
        r.options = ['--force-exclusion', '--color']
        if @changed_files.select{ |f| global_files.include?f }.empty?
          r.patterns = ruby_files
        end
    end

    [:rubocop]
  end

  def setup_shellcheck
    shell_files = filter_files_by('**/*.sh').reject{ |f| f.start_with?('modules/admin/files/home') }
    return [] if shell_files.empty?
    desc 'Ensure shell files have no errors as detected by shellcheck'
    task 'shellcheck' do
      failures = false
      result = JSON.parse(` shellcheck -f json #{shell_files.join(' ')}`)
      current_file = ''
      # uncomment can use the following if info and warning gets to noisy
      # result.select{ |i| i['level'] == 'error'}.each do |issue|
      result.each do |issue|
        if current_file.empty? || current_file != (issue['file'])
          current_file = issue['file']
          puts current_file
        end
        message = "\tline:#{issue['line']}: [SC#{issue['code']}] #{issue['message']}"
        case issue['level']
        when 'info'
          puts message.blue
        when 'warning'
          puts message.yellow
        when 'error'
          puts message.red
          failures = true
        end
      end
      abort("shellcheck: FAILED".red) if failures
      puts "shellcheck: OK".green
    end
    [:shellcheck]
  end

  def setup_python_extensions
    # Ensure python files have the correct extension so they are picked up by tox
    source_files = filter_files_by("**/files/**")
    return [] if source_files.empty?
    desc 'Ensure python files have a .py extensions so they can be checked'
    task :python_extensions do
      failures = false
      source_files.each do |source_file|
        # Skip if this is a direcory (or a symlink to a directory)
        next if File.directory?(source_file)
        # We don't need to perform CI on user files as such we skip them
        next if source_file.end_with?('.py') || source_file.start_with?('modules/admin/files/home')
        # skip zero byte files
        next if File.zero?(source_file)
        shebang = File.open(source_file) {|f| f.readline}
        # If the first line is not correctly encoded its likely a binary file
        next unless shebang.valid_encoding?
        mime_type = File.mime_type(source_file)
        if shebang =~ /^#!.*python/ || mime_type == 'text/x-python'
          failures = true
          $stderr.puts "#{source_file} have been recognized as a Python source file, hence MUST have a '.py' file extension".red
        end
      end
      abort("python_extensions: FAILED".red) if failures
      puts "python_extensions: OK".green
    end
    [:python_extensions]
  end

  def setup_hiera_defaults
    profile_yaml_files = filter_files_by("hieradata/common/profile/**/*.yaml")
    puts profile_yaml_files
    return [] if profile_yaml_files.empty?
    desc 'Check profile defaults are also in cloud.yaml'
    task :hiera_defaults do
      missing_keys = Set[]
      cloud_file = 'hieradata/cloud.yaml'
      cloud_yaml = YAML.safe_load(File.open(cloud_file))
      cloud_keys = cloud_yaml.keys.to_set
      profile_yaml_files.each do |profile_yaml_file|
        profile_yaml = YAML.safe_load(File.open(profile_yaml_file))
        missing_keys.merge(profile_yaml.keys.to_set - cloud_keys)
      end
      if missing_keys.empty?
        puts "hiera_defaults: OK".green
      else
        puts "The following defaults are missing from cloud.yaml".red
        puts "#{missing_keys.to_a.join("\n")}".red
        puts "yaml_defaults: FAILED".red
        # abort("yaml_defaults: FAILED".red)
      end
    end
    [:hiera_defaults]
  end

  def setup_common_yaml
    # ensure the common.yaml file has no qualified variables in it
    common_yaml_file = filter_files_by("hieradata/common.yaml")
    return [] if common_yaml_file.empty?
    desc 'Check hieradata/common.yaml contains only unqualified names'
    task :common_yaml do
      failures = false
      common_yaml = YAML.safe_load(File.open(common_yaml_file[0]))
      common_yaml.each_key do |key|
        next unless key.include?('::')
        key_path = key.split('::')[0..-2].join('/')
        $stderr.puts "#{key} in hieradata/common.yaml is qualified".red
        $stderr.puts "\tIf this is for labs it should go in hieradata/labs.yaml".red
        $stderr.puts "\tIf this is for production it should go in common/#{key_path}.yaml".red
        failures = true
      end
      abort("hieradata/common.yaml: FAILED".red) if failures
      puts "hieradata/common.yaml: OK".green
    end
    [:common_yaml]
  end

  def setup_spec
    # Modules known not to pass tests
    ignored_modules = ['osm']

    deps = SpecDependencies.new
    spec_modules = deps.specs_to_run(@changed_files).select do |m|
      !ignored_modules.include?(m)
    end
    return [] if spec_modules.empty?
    pattern_end = 'spec/{aliases,classes,defines,functions,hosts,integration,plans,tasks,type_aliases,types,unit}/**/*_spec.rb'
    pattern = Rake::FileList["modules/{#{spec_modules.to_a.join(',')}}/#{pattern_end}"].to_a
    return [] if pattern.empty?

    desc 'Run spec for modules'
    task :spec do
      args = ['-t', 'rspec', '--']
      args.concat(pattern)
      ParallelTests::CLI.new.run(args)
    end
    [:spec]
  end

  def setup_per_module_tox
    tasks = []
    namespace :tox do
      # first let's select only the python files
      python_files = filter_files_by('**/*.py')
      return tasks if python_files.empty?
      deps = SpecDependencies.new
      deps.tox_to_run(python_files).each do |module_name|
        test_name = "tox:#{module_name}"
        # Test already added
        next if tasks.include? test_name
        tasks << test_name
        desc "Run tox in module #{module_name}"
        task module_name do
          tox_ini = "modules/#{module_name}/tox.ini"
          if @changed_files.include?(tox_ini)
            raise "Running tox in #{module_name} failed".red unless system("tox -r -c #{tox_ini}")
          else
            raise "Running tox in #{module_name} failed".red unless system("tox -c #{tox_ini}")
          end
        end
      end
    end
    tasks
  end

  def setup_tox
    tasks = []
    namespace :tox do
      if @changed_files.include?('tox.ini') || @changed_files.include?('rake_modules/taskgen.rb')
        py_files = sort_python_files(Dir.glob('**/*.py'))
        ENV['TOX_PY2_FILES'] = py_files[:py2].join(' ')
        ENV['TOX_PY3_FILES'] = py_files[:py3].join(' ')
        desc 'Refresh the tox environment'
        task :update do
          raise "Running tox failed" unless system('tox -r')
        end
        tasks << 'tox:update'
      else
        admin_data_files = filter_files_by('modules/admin/data/**')
        unless admin_data_files.empty?
          desc 'Run tox for the admin data file'
          task :admin do
            res = system('tox -e admin')
            raise "Tox tests for admin/data/data.yaml failed!".red unless res
          end
          tasks << 'tox:admin'

          desc 'Run tox to check admin data file matches schema'
          task :adminschema do
            res = system('tox -e adminschema')
            raise "Tox tests for admin/data/data.yaml following admin/data/schema.yaml failed!".red unless res
          end
          tasks << 'tox:adminschema'
        end
        mtail_files = filter_files_by("modules/mtail/files/**")
        unless mtail_files.empty?
          desc 'Run tox for mtail'
          task :mtail do
            res = system("tox -e mtail")
            raise 'Tests for mtail failed!'.red unless res
          end
          tasks << 'tox:mtail'
        end
        alerts_files = filter_files_by("modules/alerts/files/**")
        unless alerts_files.empty?
          desc 'Run tox for alerts'
          task :alerts do
            res = system("tox -e alerts")
            raise 'Tests for alerts failed!'.red unless res
          end
          tasks << 'tox:alerts'
        end
        tables_catalog_files = filter_files_by("modules/mediawiki/files/mariadb/**")
        unless tables_catalog_files.empty?
          desc 'Run tox for tables catalog'
          task :tables_catalog do
            res = system("tox -e tables_catalog")
            raise 'Tests for tables_catalog failed!'.red unless res
          end
          tasks << 'tox:tables_catalog'
        end
        tslua_files = filter_files_by("modules/profile/files/trafficserver/**")
        unless tslua_files.empty?
          desc 'Run tox for tslua'
          task :tslua do
            res = system("tox -e tslua")
            raise 'Tests for tslua failed!'.red unless res
          end
          tasks << 'tox:tslua'
        end
        nagios_common_files = filter_files_by("modules/nagios_common/files/check_commands/**")
        unless nagios_common_files.empty?
          desc 'Run tox for nagios_common'
          task :nagios_common do
            res = system("tox -e nagios_common")
            raise 'Tests for nagios_common failed!'.red unless res
          end
          tasks << 'tox:nagios_common'
        end
        grafana_files = filter_files_by("modules/grafana/files/**")
        unless grafana_files.empty?
          desc 'Run tox for grafana'
          task :grafana do
            res = system("tox -e grafana")
            raise 'Tests for grafana failed!'.red unless res
          end
          tasks << 'tox:grafana'
        end
        smart_data_dump_files = filter_files_by("modules/smart/files/**")
        unless smart_data_dump_files.empty?
          desc 'Run tox for smart_data_dump'
          task :smart_data_dump do
            res = system("tox -e smart_data_dump")
            raise 'Tests for smart_data_dump failed!'.red unless res
          end
          tasks << 'tox:smart_data_dump'
        end
        prometheus_files = filter_files_by("modules/prometheus/files/**")
        unless prometheus_files.empty?
          desc 'Run tox for prometheus'
          task :prometheus do
            res = system("tox -e prometheus")
            raise 'Tests for prometheus failed!'.red unless res
          end
          tasks << 'tox:prometheus'
        end
        openstack_puppetenc_files = filter_files_by("modules/openstack/files/puppet/master/encapi/**")
        unless openstack_puppetenc_files.empty?
          desc 'Run tox for openstack puppet enc'
          task :openstack_puppetenc do
            res = system("tox -e openstack_puppetenc")
            raise 'Tests for openstack_puppetenc failed!'.red unless res
          end
          tasks << 'tox:openstack_puppetenc'
        end
        # Get all python files that don't have a tox.ini in their module
        py_files = sort_python_files(filter_files_by("*.py"))

        unless py_files[:py2].empty?
          desc 'Run flake8 on python2 files via tox'
          task :flake8 do
            shell_python2_files = Shellwords.join(py_files[:py2])
            raise "Flake8 failed".red unless system("tox -e py2-pep8 -- #{shell_python2_files}")
          end
          tasks << 'tox:flake8'
        end

        unless py_files[:py3].empty?
          desc 'Run flake8 on python3 files via tox'
          task :flake8_3 do
            shell_python3_files = Shellwords.join(py_files[:py3])
            raise "Flake8 failed" unless system("tox -e py3-pep8 -- #{shell_python3_files}")
          end
          tasks << 'tox:flake8_3'
        end

        # commit message
        desc 'Check commit message'
        task :commit_message do
          raise 'Invalid commit message'.red unless system("tox -e commit-message")
        end
        tasks << 'tox:commit_message'

        wmcs_files = filter_files_by("modules/profile/files/wmcs/***")
        unless wmcs_files.empty?
          desc 'Run wmcs tests'
          task :wmcs do
            res = system("tox -e wmcs")
            raise 'Tests for wmcs failed!'.red unless res
          end
          tasks << 'tox:wmcs'
        end

        wmcs_replica_cnf_files = filter_files_by("modules/profile/files/wmcs/nfs/replica_cnf_api_service/**")
        unless wmcs_replica_cnf_files.empty?
          desc 'Run wmcs replica_cnf tests'
          task :wmcs_replica_cnf do
            res = system("tox -e wmcs-replica_cnf_api_service")
            raise 'Tests for wmcs replica cnf failed!'.red unless res
          end
          tasks << 'tox:wmcs_replica_cnf'
        end
      end
    end

    desc 'Run all the tox-related tasks'
    task :tox => tasks
    [:tox]
  end
end

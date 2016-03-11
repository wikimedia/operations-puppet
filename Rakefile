# This rakefile is meant to trigger your local puppet-linter. To take
# advantage of that powerful linter, you must have the puppet and
# puppet-lint gems:
#
#   $ sudo gem install puppet
#   $ sudo gem install puppet-lint
#
# Then run the linter using rake (a ruby build helper):
#
#   $ rake lint
#
# A list of top errors can be obtained using:
#   $ rake lint |rev |cut -d\  -f4- | rev | sort | uniq -c | sort -rn
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

require 'bundler/setup'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

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

Run puppet style checker:
  rake lint
"

end

task :run_puppet_lint do
    system('puppet-lint .')
end

desc 'Run all build/tests commands (CI entry point)'
task test: [:rubocop]

desc "Build documentation"
task :doc do
    doc_cmd = [
        "puppet doc",
        "--mode rdoc",
        "--all",  # build all references
        "--manifestdir manifests",
        "--modulepath modules",
    ].join(' ')
    puts "Running #{doc_cmd}"
    system(doc_cmd)
end

desc "Lint puppet files"
task :lint => :run_puppet_lint

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

namespace :varnish do

    def glob_vcl_files
        Dir.glob("{templates,modules}/**/*.vcl*").sort
    end

    desc "Attempt to compile VCL to C language"
    task :vcl2c do

        require "erb"

        class VclContext

            # Scope hack
            attr_reader :sip
            attr_reader :scope

            def initialize
                # Yeah we shouldn't hardcode this
                # This directory should also somehow passed to our .vtc files
                # varnish v1 -arg "-p vcl_dir=/tmp/varnishtests/ -p vcc_err_unref=false" -vcl+backend
                # include "/tmp/varnishtests/wikimedia_maps-backend.vcl";
                #
                @dstdir = "/tmp/varnishtests/"

                # Those should be per template fixtures
                @sip = '127.0.0.1'
                @vcl_config = {
                    'bits_domain' => 'bits.wikimedia.org',
                    'static_host' => 'en.wikipedia.org',
                    'upload_domain' => 'upload.wikimedia.org',
                    'purge_host_regex' => '^(?!upload\.wikimedia\.org)',
                }
                @cache_route = 'fake_cache_route'
                @varnish_directors = {}
                @directors = {}
                @name = 'Some_name'
                @hostname = 'hostname.example.org'
                @ipaddress = '127.0.0.1'

                # Yeah we shouldn't hardcode these
                @layer = 'backend'
                @vcl = 'maps-backend'

                # Handle scope.lookupvar()
                s = Class.new do
                    def lookupvar(var)
                        vars = {
                            '::network::constants::all_networks_lo' => [
                                '127.0.0.0/8', '::1/128'
                            ],
                        }
                        vars[var]
                    end
                end
                @scope = s.new
            end
        end

        bad = 0
        glob_vcl_files.each do |vcl_file|
            template = ERB.new(File.read(vcl_file), nil, '-')
            template.filename = vcl_file
            begin
                # Inject fixture in the context and render
                renderer = template.def_class(VclContext).new
                renderer.result

                # because ruby
                vcl = renderer.instance_variable_get(:@vcl)
                layer = renderer.instance_variable_get(:@layer)
                dstdir = renderer.instance_variable_get(:@dstdir)

                destfile = File.basename(template.filename, ".erb")
                if destfile == "wikimedia-common.inc.vcl"
                    destfile = "wikimedia-common_" + vcl  + ".inc.vcl"
                end
                if destfile == "wikimedia-" + layer + ".vcl"
                    destfile = "wikimedia_" + vcl + ".vcl"
                end
                if destfile == "wikimedia-common.inc.vcl"
                    destfile = "wikimedia-common_" + vcl + ".inc.vcl"
                end

                File.write(dstdir + destfile, renderer.result)
            rescue NameError, NoMethodError, SyntaxError => e
                bad += 1
                puts "#{vcl_file} FAILED:"
                puts e.to_s.gsub(/^/, 'ERR> ')
            else
                puts "#{vcl_file} PASSED"
            end
        end
        if bad > 0
            puts "\nERR> #{bad} template(s) can not be expanded\n\n"
            fail
        end
    end
end

# lint
# amass profit
# donate!

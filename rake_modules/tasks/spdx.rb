# SPDX-License-Identifier: Apache-2.0
require 'rake_modules/monkey_patch'

SPDX_GLOB = "{modules,manifests,rake_module,utils}/{**/*,*}"
SPDX_TAG = "SPDX-License-Identifier: Apache-2.0"
class UnknownExtensionError < StandardError
  attr_reader :filename
  def initialize(filename, msg = "Unknown Extension")
    @filename = filename
    super(msg)
  end
end

class NoCommentSupoportError < StandardError
end

def extract_email(string)
   string.scan(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/).sort
end

def check_module_contributors(module_path)
  module_contributors = extract_email(`git shortlog -se -- #{module_path}`)
                          .reject {|email| email.end_with?('@wikimedia.org') }
  allowed_contributors = extract_email(File.read('CONTRIBUTORS'))
  module_contributors - allowed_contributors
end

def check_spdx_licence(file_list)
  # Check a list of files for an spdx licence header
  missing_licence = []
  file_list.each do |filename|
    next unless File.file?(filename)
    # For now skip files with no extension as we are unable to detect the comment style
    next unless filename.include?('.')
    # Skip 3rd party files
    next if filename.end_with?('.original.py')
    if File.binary?(filename)
      puts 'skipping ' + filename
      next
    end
    begin
      missing_licence << filename unless File.foreach(filename).grep(/SPDX-License-Identifier:/).any?
    rescue ArgumentError => error
      STDERR.puts "Error Could not read #{filename}: #{error}".red
    end
  end
  missing_licence
end

def comment_line(filename, line)
  # format a line as a comment using the file type specific comment
  # filetype is calculated based on the file extension
  ext = filename.split('.')[-1].downcase.strip
  case ext
  when /\A(?:erb|epp)\z/
    "<%#- #{line} -%>\n"
  when /\A(?:jinja)\z/
    "{# #{line} #}\n"
  when /\A(?:html|md|markdown|xml)\z/
    "<!-- #{line} -->\n"
  when /\A(?:css)\z/
    "/* #{line} */\n"
  when /\A(?:vcl|php|groovy|js)\z/
    "// #{line}\n"
  when /\A(?:cf|cfg|csh|ini|pl|pp|properties|py|R|rb|rc|service|sh|stp|vtc|yaml|yml)\z/
    "# #{line}\n"
  when /\A(?:lua|sql)\z/
    "-- #{line}\n"
  when /\A(?:json|pem|key)\z/
    # Theses files don't support comments so skip them
    raise NoCommentSupoportError
  else
    raise UnknownExtensionError, filename
  end
end

def add_spdx_tags(files)
  # Add the SPDX_TAGS near the top of a each file passed
  unknown_files = []
  files.each do |filename|
    begin
      tag = comment_line(filename, SPDX_TAG)
    rescue UnknownExtensionError => error
      unknown_files << error.filename
      next
    rescue NoCommentSupoportError
      next
    end
    puts "#{filename}: adding spdx licence"
    File.open(filename, 'r+') do |fh|
      while line = fh.readline  # rubocop:disable Lint/AssignmentInCondition
        break unless line[0..1] == '#!'
      end
      rewind_pos = fh.pos - line.size
      file_end = line + fh.read
      fh.seek(rewind_pos)
      fh.write(tag)
      fh.write(file_end)
    end
  end
  unless unknown_files.empty?
    puts(("Unable to add tag to the following files:\n" + unknown_files.join("\n")).yellow)
  end
end

def setup_spdx(git)
  changed_files = git.changes_in_head.select{ |f| File.fnmatch(SPDX_GLOB, f, File::FNM_EXTGLOB) }
  new_files = git.new_files_in_head.select{ |f| File.fnmatch(SPDX_GLOB, f, File::FNM_EXTGLOB) }
  tasks = []
  unless changed_files.empty?
    namespace :'spdx:check' do
      desc "Check changed files"
      task :changed do
        missing_licence = check_spdx_licence(changed_files)
        if missing_licence.empty?
          abort("The following are missing a SPDX licence header:\n#{missing_licence.join("\n")}".red)
        end
        puts 'SPDX licence: OK'.green
      end
    end
  end
  unless new_files.empty?
    missing_licence = check_spdx_licence(new_files)
    namespace :'spdx:check' do
      desc "Check changed files"
      task :new_files do
        unless missing_licence.empty?
          msg = <<~ERROR
          The following are missing a SPDX licence header:

          #{missing_licence.join("\n")}

          Use the following command to automatically add tags

            `bundle exec rake spdx:convert:new_files`

          ERROR
          abort(msg.red)
        end
        puts 'SPDX licence: OK'.green
      end
    end
    tasks << 'spdx:check:new_files'
    namespace :'spdx:convert' do
      desc "Convert a module to SPDX"
      task :new_files do
        if missing_licence.empty?
          puts 'OK: all new files an spdx header'
          exit
        end
        add_spdx_tags(missing_licence)
      end
    end
    tasks << 'spdx:check:new_files'
  end
  tasks
end

namespace :spdx do
  namespace :check do
    desc "Check all files"
    task :all do
      missing_licence = check_spdx_licence(FileList[SPDX_GLOB])
      abort("The following are missing a SPDX licence header:\n#{missing_licence}".red) unless missing_licence.empty?
      puts 'SPDX licence: OK'.green
    end
  end
  namespace :convert do
    desc "Convert a module to SPDX"
    task :module, [:module] do |_t, args|
      module_path = "modules/#{args[:module]}"
      abort("#{args[:module]}: does not exist".red) unless File.directory?(module_path)
      unsigned_contibutors = check_module_contributors(module_path)
      unless unsigned_contibutors.empty?
        abort("The following contributors have not agreeded to the SPDX licence:\n#{unsigned_contibutors.join("\n")}".red)
      end
      glob = "#{module_path}/**/*"
      missing_licence = check_spdx_licence(FileList[glob])
      add_spdx_tags(missing_licence)
    end
  end
end

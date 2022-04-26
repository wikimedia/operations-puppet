# SPDX-License-Identifier: Apache-2.0

SPDX_GLOB = "{modules,manifests,rake_module,utils}/{**/*,*}"
SPDX_HEADER = "# SPDX-License-Identifier: Apache-2.0\n"
SPDX_LICENCE_PATH = 'rake_modules/resources/APACHE-2.0'

def check_spdx_licence(file_list)
  # Check a list of files for an spdx licence header
  missing_licence = []
  file_list.each do |filename|
    missing_licence << filename unless File.foreach(filename).grep(/SPDX-License-Identifier:/).any?
  end
  missing_licence
end

def setup_spdx(git)
  changed_files = git.changes_in_head.select{ |f| File.fnmatch(SPDX_GLOB, f, File::FNM_EXTGLOB) }
  new_files = git.new_files_in_head.select{ |f| File.fnmatch(SPDX_GLOB, f, File::FNM_EXTGLOB) }
  tasks = []

  namespace :'spdx:check' do
    unless changed_files.empty?
      desc "Check changed files"
      task :changed do
        missing_licence = check_spdx_licence(changed_files)
        if missing_licence.empty?
          abort("The following are missing a SPDX licence header:\n#{missing_licence.join("\n")}".red)
        end
        puts 'SPDX licence: OK'.green
      end
    end
    unless new_files.empty?
      desc "Check changed files"
      task :new_files do
        missing_licence = check_spdx_licence(new_files)
        unless missing_licence.empty?
          msg = <<~ERROR
          The following are missing a SPDX licence header:

          #{missing_licence.join("\n")}

          Please add a header like the following:

          #{SPDX_HEADER}

          ERROR
          abort(msg.red)
        end
        puts 'SPDX licence: OK'.green
      end
      tasks << 'spdx:check:new_files'
    end
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
end

# SPDX-License-Identifier: Apache-2.0
Puppet::Functions.create_function(:'wmflib::list_secrets', Puppet::Functions::InternalFunction) do
  # returns a list of regular files (directories and symlinks are ignored) from the private module
  # @param secret_dir the name of the secret directory to list. A path relative to the secret module
  # @param glob the glob used to match files inside secret_dir. default: '*'
  # @param mod_name the name of the secret module. default: 'secret'
  # @param secs_subdir the subdir of the secret module where secrets are stored. default: '/secrets/'
  # @return Array[String] list of files
  dispatch :list_secrets do
    param 'String', :secret_dir
    optional_param 'String', :glob
    optional_param 'String', :mod_name
    optional_param 'String', :secs_subdir
    return_type 'Array[String]'
  end
  def list_secrets(secret_dir, glob = '*', mod_name = 'secret', secs_subdir = '/secrets/')
    mod = Puppet::Module.find(mod_name)
    fail("list_secrets(): Module #{mod_name} not found") unless mod
    secret_path = File.join(mod.path, secs_subdir, secret_dir)
    fail("list_secrets(): Invalid secret_dir #{secret_dir}") unless File.directory?(secret_path)
    secret_files = Dir.glob(File.join(secret_path, glob)).select do |f|
      !File.symlink?(f) && File.file?(f)
    end

    sub_path = File.join(mod.path, secs_subdir)
    secret_files.sort.map { |secret_file| secret_file.sub(sub_path, "") }
  end
end

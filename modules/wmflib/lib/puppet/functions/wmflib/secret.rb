Puppet::Functions.create_function(:'wmflib::secret', Puppet::Functions::InternalFunction) do
  # returns a file from the private module, encoding as a Binary type if needed
  # @param secret the name of the secret to load.  A path relative to the secret module
  # @param binary Boolean to specify if the file content is binary or not.  default: false
  # @param mod_name the name of the secret module. default: 'secret'
  # @param secs_subdir the subdir of the secret module where secrets are stored. default: '/secrets/'
  # @return Variant[String, Binary] The content of the secret file.  If binary is specified
  # a Binary type will be returned to ensure compatibility with a json catalouge
  dispatch :secret do
    scope_param
    param 'String', :secret
    optional_param 'Boolean', :binary
    optional_param 'String', :mod_name
    optional_param 'String', :secs_subdir
    return_type 'Variant[String,Binary]'
  end
  def secret(scope, secret, binary = false, mod_name = 'secret', secs_subdir = '/secrets/')
    mod = Puppet::Module.find(mod_name)
    fail("secret(): Module #{mod_name} not found") unless mod
    path = File.join(mod.path + secs_subdir + secret)
    path = Puppet::Parser::Files.find_file(path, scope.compiler.environment)
    fail(ArgumentError, "secret(): invalid secret #{secret}") unless path && Puppet::FileSystem.exist?(path)
    if binary
      Puppet::Pops::Types::PBinaryType::Binary.from_binary_string(Puppet::FileSystem.binread(path))
    else
      Puppet::FileSystem.read_preserve_line_endings(path)
    end
  end
end

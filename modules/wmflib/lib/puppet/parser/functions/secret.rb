require 'pathname'

#
# Usage in a file resource.
#
# Get content of 'modules/secret/secrets/path/to/secret_pw'
#   content => secret('path/to/secret_pw')
#
# Get content of 'modules/certificates/secrets/path/to/secret_key'
#   content => secret('path/to/secret_key', 'certificates')
#
module Puppet::Parser::Functions
  newfunction(:secret, :type => :rvalue) do |args|
    mod_name = 'secret'
    secs_subdir = '/secrets/'

    if args.length < 1 || args.length > 2 || !args.first.is_a?(String) !args[1].is_a?(String)
      fail(ArgumentError, 'secret(): takes one or two string args')
    end
    in_path = args.first

    if args.length == 2
      mod_name = args[1]
    end

    if mod = Puppet::Module.find(mod_name)
       mod_path = mod.path()
    else
      fail("secret(): Module #{mod_name} not found")
    end

    sec_path = mod_path + secs_subdir + in_path
    final_path = Pathname.new(sec_path).cleanpath()

    # Bail early if it's not a regular, readable file
    if !final_path.file? || !final_path.readable?
      fail(ArgumentError, "secret(): invalid secret #{in_path}")
    end

    return final_path.read()
  end
end

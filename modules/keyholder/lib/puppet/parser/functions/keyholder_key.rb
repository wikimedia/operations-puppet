
require 'fileutils'
require 'English'

# keyholder_key(name, create)
# This puppet parser function works like secret() but it can generate
# a new ssh key pair if the specified key doesn't already exist.
#
#   Required parameters:
#     name   (the name of the key - e.g 'my_ssh_key')
#   Optional parameters:
#     create (if specified, reads the public key instead of the private key)
#
module Puppet::Parser::Functions
  newfunction(:keyholder_key, :type => :rvalue, :arity => -2) do |args|
    key_name = args[0]
    mod = Puppet::Module.find('secret')
    raise Puppet::ParseError, "keyholder_key(): Module 'secret' not found." unless mod
    fullpath = File.join(mod.path, 'secrets', 'keyholder')

    raise Puppet::ParseError, "keyholder_key(): secrets directory (#{fullpath}) does not exist." unless File.directory?(fullpath)
    key_file = File.join(fullpath, key_name)

    begin
      # generate a keypair if one does not exist
      # but only if the create argument was passed as true
      if !File.exists?(key_file) && args[1] == true
        full_cmd = "/usr/bin/ssh-keygen -q -t rsa -b 2048 -N '' -f #{key_file}"
        %x(full_cmd)
        rc = $CHILD_STATUS.to_i
        raise "command \"#{full_cmc}\" return code is #{rc}" unless $CHILD_STATUS.success?
      end
    rescue => e
      raise Puppet::ParseError, "keyholder_key: Unable to generate ssh key (#{e})"
    end

    if args[2] == 'fingerprint'
      return %x(`/usr/bin/ssh-keygen -l -f #{key_file}`).strip
    elsif args[2] == 'pubkey'
      return IO.read("#{key_file}.pub")
    else
      return IO.read(key_file)
    end
  end
end

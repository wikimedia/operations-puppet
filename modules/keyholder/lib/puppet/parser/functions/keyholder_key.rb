
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
    fullpath = File.join(mod.path, 'secrets')

    raise Puppet::ParseError, "keyholder_key(): secrets directory (#{fullpath}) does not exist." unless File.directory?(fullpath)

    begin
      # generate a keypair if one does not exist
      # but only if the create argument was passed as true
      if !File.exists?("#{fullpath}/#{key_name}") && args[1] == true
        %x(`/usr/bin/ssh-keygen -t rsa -b 2048 -P '' -f #{fullpath}/#{key_name}`)
        raise "ssh-keygen return code is #{rc}" unless $CHILD_STATUS.success?
      end
    rescue => e
      raise Puppet::ParseError, "keyholder_key(): Unable to generate ssh key (#{e})"
    end

    if args[2] == 'fingerprint'
      return %x(`/usr/bin/ssh-keygen -l -f #{fullpath}/#{key_name}`)
    elsif args[2] == 'pubkey'
      return File.open("#{fullpath}/#{key_name}.pub").read
    else
      return File.open("#{fullpath}/#{key_name}").read
    end
  end
end

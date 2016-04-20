
require 'fileutils'

# keyholder_key(name, create)
# This puppet parser function works like secret() but it can generate
# a new ssh key pair if the specified key doesn't already exist.
#
#   Required parameters:
#     :name   (the name of the key - e.g 'my_ssh_key')
#   Optional parameters:
#     :create (if specified, reads the public key instead of the private key)
#
module Puppet::Parser::Functions
  newfunction(:keyholder_key, :type => :rvalue) do |args|
    key_name = args[0]

    if mod = Puppet::Module.find('secret')
      mod_path = mod.path()
      fullpath = Pathname.new(mod_path + '/secrets/').cleanpath()
    else
      raise Puppet::ParseError, "keyholder_key(): Module 'secret' not found."
    end

    unless File.directory?(fullpath) then
      raise Puppet::ParseError, "keyholder_key(): secrets directory (#{fullpath}) does not exist."
    end

    begin
      # generate a keypair if one does not exist
      unless File.exists?("#{fullpath}/#{key_name}") then
        # but only if the create argument was passed as true
        if args.length > 1 && args[1] == true
          %x[/usr/bin/ssh-keygen -t rsa -b 2048 -P '' -f #{fullpath}/#{key_name}]
          rc = $?
          unless rc == 0
            raise "ssh-keygen return code is #{rc}"
          end
        end
      end
    rescue => e
      raise Puppet::ParseError, "keyholder_key(): Unable to generate ssh key (#{e})"
    end

    begin
      return File.open("#{fullpath}/#{key_name}").read
    rescue => e
      raise Puppet::ParseError, "keyholder_key(): Unable to read ssh #{key_part.to_s} key (#{e})"
    end
  end
end

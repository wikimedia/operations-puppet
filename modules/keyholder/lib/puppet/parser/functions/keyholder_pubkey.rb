
# keyholder_pubkey('key_name')
# return the public key part of a keypair which was generated with
# keyholder_key()
#
# Required Parameters:
#   :key_name (the name of the key - e.g 'my_ssh_key')

# make sure keyholder_key.rb is loaded
require File.join([File.expand_path(File.dirname(__FILE__)), 'keyholder_key.rb'])

module Puppet::Parser::Functions
  newfunction(:keyholder_pubkey, :type => :rvalue) do |args|
    unless args.length == 1 then
      raise Puppet::ParseError, "keyholder_pubkey(): key_name argument is required"
    end
    key_name = args[0].chomp

    # call once to generate the keypair (in case it doesn't already exist)
    key = function_keyholder_key([key_name, true])

    # call again to get the public key part
    pub_key = function_keyholder_key(["#{key_name}.pub", false])
    return pub_key.scan(/^.* (.*) .*$/)[0][0]
  end
end


# keyholder_pubkey('key_name')
# return the public key part of a keypair which is generated with
# keyholder_key()
#
# Required Parameters:
#   :key_name (the name of the key - e.g 'my_ssh_key')

module Puppet::Parser::Functions
  newfunction(:keyholder_pubkey, :type => :rvalue, :arity => 1) do |args|
    key_name = args[0].chomp

    # call keyholder_key to generate a key (if none exists)
    # and then return the public key part
    pub_key = function_keyholder_key(["#{key_name}", 'pubkey'])
    return pub_key.scan(/^(.*? .*?) .*$/).flatten[0]
  end
end


# keyholder_fingerprint('key_name')
# return the fingerprint of a keypair which is generated with
# keyholder_key()
#
# Required Parameters:
#   key_name (the name of the key - e.g 'my_ssh_key')

module Puppet::Parser::Functions
  newfunction(:keyholder_fingerprint, :type => :rvalue, :arity => 1) do |args|
    key_name = args[0].chomp

    # call keyholder_key to generate the key and return the fingerprint
    fp = function_keyholder_key(["#{key_name}", 'fingerprint'])
    return fp.scan(/^.*? (.*?) .*$/).flatten[0]
  end
end

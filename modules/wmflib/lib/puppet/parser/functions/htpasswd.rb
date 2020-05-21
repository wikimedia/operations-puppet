# == Function htpasswd( string $password, string $salt)
#
# Generate a password entry for a htpasswd file using the modified md5 digest
# method from apr.
#
require 'apr1md5'

module Puppet::Parser::Functions
  newfunction(:htpasswd, :type => :rvalue, :arity => 2) do |args|
    generator = Apr1Md5.new args[1]
    generator.encode args[0]
  end
end

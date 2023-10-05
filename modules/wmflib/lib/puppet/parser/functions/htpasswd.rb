# == Function htpasswd( string $password, string $salt)
#
# Generate a password entry for a htpasswd file using the modified md5 digest
# method from apr.
# Note: the salt must be an 8-character string.
#
# See <https://httpd.apache.org/docs/current/misc/password_encryptions.html>
# for an explanation about the apr1md5 format.
#
require_relative '../../../puppet_x/wmflib/apr1md5.rb'

module Puppet::Parser::Functions
  newfunction(:htpasswd, :type => :rvalue, :arity => 2) do |args|
    if args[1].length != 8
      fail(ArgumentError, 'htpasswd(): salt must be 8 characters')
    end
    generator = PuppetX::Wmflib::Apr1Md5.new args[1]
    generator.encode args[0]
  end
end

# == Function: apt_version
#
# === Description
#
# Gets the version of an apt package. If the package is installed, gets
# the installed version. If not, gets the candidate version. If no such
# package exists, returns nil.
#
# === Examples
#
#    apt_version('apache2')  # => "2.4.7-1ubuntu4"
#    apt_version('fake123')  # => nil
#
module Puppet::Parser::Functions
  newfunction(
    :apt_version,
    :type => :rvalue,
    :doc  => <<-END
      Gets the version of an apt package. If the package is installed, gets
      the installed version. If not, gets the candidate version. If no such
      package exists, returns nil.

      Examples:

         apt_version('apache2')  # => "2.4.7-1ubuntu4"
         apt_version('fake123')  # => nil

    END
  ) do |args|
    unless args.length == 1 and args.first.is_a? String
        raise Puppet::ParseError, 'apt_version() takes a single string argument'
    end
    cmd = "/usr/bin/apt-cache policy -q #{args.first} 2>/dev/null"
    /: ([^(]\S*)/ =~ Facter::Util::Resolution.exec(cmd) ? $1 : nil
  end
end

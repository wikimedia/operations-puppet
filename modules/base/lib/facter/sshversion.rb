# Copyright: 2015 Wikimedia Foundation, Inc.
#
# Fact: sshversion
#
# Purpose: Determine the version of openssh currently installed
require 'facter'

Facter.add("sshversion") do
  setcode do
    version_string = Facter::Util::Resolution.exec('/usr/bin/ssh -V')
    match = /OpenSSH_(.+)\s/.match(version_string)

    match[1]
  end
end

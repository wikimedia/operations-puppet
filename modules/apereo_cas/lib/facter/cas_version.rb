# SPDX-License-Identifier: Apache-2.0
require 'facter'

Facter.add(:cas_version) do
  confine :kernel => 'Linux'
  confine do
    File.file?('/usr/share/doc/cas/README.Debian')
    Facter::Util::Resolution.which('dpkg-query')
  end
  setcode do
    version = Facter::Util::Resolution.exec("dpkg-query --showformat='${Version}' --show cas")
    version.split('+')[0]
  end
end
if $PROGRAM_NAME == __FILE__
  puts Facter.value(:cas_version)
end

# saltversion.rb
#
# This fact fetches the installed salt-minion version from dpkg

require 'facter'

Facter.add(:saltversion) do
  setcode do
    Facter::Util::Resolution.exec.("dpkg-query -W -f='${Version}' salt-minion")
  end
end

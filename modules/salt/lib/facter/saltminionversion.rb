# saltversion.rb
#
# This fact fetches the installed salt-minion version from dpkg

require 'facter'

Facter.add(:saltminionversion) do
  setcode do
    Facter::Util::Resolution.exec("dpkg -s salt-minion | grep Version | cut -d ' ' -f 2").chomp
  end
end

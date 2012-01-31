# projectgid.rb
# 
# This fact provides project_gid (gidNumber) for projects in labs.
# This is used to set the udp_send_channel port in ganglia's gmond.conf.

require 'facter'

project_name = Facter.value(:instanceproject)
Facter.add(:project_gid) do
  setcode do
    Facter::Util::Resolution.exec("getent group #{project_name} | cut -d : -f 3").chomp
  end
end

# projectgid.rb
# 
# This fact provides project_gid (gidNumber) for projects in labs.
# This is used to set the udp_send_channel port in ganglia's gmond.conf.

require 'facter'

Facter.add(:project_gid) do
  setcode do
    if not File.exist? '/etc/ganglia/gmond.conf'
      return "none"
    end
    project_name = Facter::Util::Resolution.exec("egrep -A1 '^cluster {' /etc/ganglia/gmond.conf | awk -F '\"' '/name =/ {print $2}'").chomp
    gid = Facter::Util::Resolution.exec("getent group project-#{project_name} | cut -d : -f 3")
    if gid
      gid.chomp
    else
      "none"
    end
  end
end

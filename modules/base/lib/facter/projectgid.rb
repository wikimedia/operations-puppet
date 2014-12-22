# projectgid.rb
# 
# This fact provides project_gid (gidNumber) for projects in labs.

require 'facter'

Facter.add(:project_gid) do
  setcode do
    domain = Facter::Util::Resolution.exec("hostname -d").chomp
    if domain.include? "wmflabs"
      # Dig deep in ldap for the project name.  This code echoes that in the
      # labs firstboot.sh
      binddn=Facter::Util::Resolution.exec("grep 'binddn' /etc/ldap.conf | sed 's/.* //'")
      bindpw=Facter::Util::Resolution.exec("grep 'bindpw' /etc/ldap.conf | sed 's/.* //'")
      hostsou=Facter::Util::Resolution.exec("grep 'nss_base_hosts' /etc/ldap.conf | sed 's/.* //'")

      id=Facter::Util::Resolution.exec("curl http://169.254.169.254/1.0/meta-data/instance-id 2> /dev/null")
      idfqdn="#{id}.#{domain}"
      project=Facter::Util::Resolution.exec("ldapsearch -x -D #{binddn} -w #{bindpw} -b #{hostsou} \"dc=#{idfqdn}\" puppetvar | grep 'instanceproject' | sed 's/.*=//'")
      if not project
        return "none"
      end

      gid = Facter::Util::Resolution.exec("getent group project-#{project} | cut -d : -f 3")
      if gid
        gid.chomp
      else
        "none"
      end
    else
      "none"
    end
  end
end

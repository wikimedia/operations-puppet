# Gather the DRBD role for each volume and report it
Facter.add('drbd_role') do
  confine :kernel => :linux
  confine do
    FileTest.exists?('/usr/sbin/drbd-overview')
  end
  setcode do
    drbd_info = Facter::Util::Resolution.exec('/usr/sbin/drbd-overview')
    drbd_role = {}
    drbd_info.split(/\n/).each do |line|
      next unless line =~ /^\s+\d.*/
      sections = line.split(' ')
      drbd_role[sections[0].sub(%r{^\d+:(\w+)/.*$}, '\1')] = sections[2].split("/")[0].downcase
    end
    drbd_role
  end
end

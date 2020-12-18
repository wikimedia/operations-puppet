# Gather the DRBD role for each volume and report it
if FileTest.exists?('/usr/sbin/drbd-overview')
  Facter.add('drbd_role') do
      confine :kernel => :linux
      setcode do
        drbd_info = `/usr/sbin/drbd-overview`
        drbd_role = {}
        drbd_info.split(/\n/).each do |line|
          next unless line =~ /^\s+\d.*/
          sections = line.split(' ')
          drbd_role[sections[0].sub(%r{^\d+:(\w+)/.*$}, '\1')] = sections[2].split("/")[0].downcase
        end
        drbd_role
      end
  end
end

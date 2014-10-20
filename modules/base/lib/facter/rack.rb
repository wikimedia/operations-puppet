# These two are based on a heuristic and assumptions and are possible to break
Facter.add('rackrow') do
    confine :kernel => %w{Linux FreeBSD OpenBSD}
    setcode do
        lldppeers = Facter.value('lldppeers')
        lldppeers.split(',').gsub('asw-', '')
    end
end
Facter.add('rack') do
    confine :kernel => %w{Linux FreeBSD OpenBSD}
    setcode do
        rackrow = Facter.value('rackrow')
        lldp_eth0 = Facter.value('lldpswport_eth0')
        if ( lldp_eth0 =~ /[gx]e-(\d+)\/\d\/\d(\.\d+)/ )
            rack = $1 + 1 #We don't have 0 based racks
        else
            rack = 'Unknown'
        end
        "#{rack}-#{rackrow}"
    end
end

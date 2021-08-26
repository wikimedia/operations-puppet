require 'facter'
require 'rexml/document'

Facter.add(:lldp) do
  confine :kernel => %w{Linux FreeBSD OpenBSD}
  confine do
    File.exists?('/usr/sbin/lldpctl')
  end

  setcode do
    primary = Facter.value(:networking)['primary']
    lldp = {parent: nil}
    data = Facter::Util::Resolution.exec('/usr/sbin/lldpctl -f xml')
    document = REXML::Document.new(data)

    document.elements.each('lldp/interface') do |interface|
      eth = interface.attributes['name']
      desc = interface.attributes['descr']
      lldp[eth] ||= {'neighbors' => []}

      interface.elements.each('chassis/name') do |switch|
        lldp[eth]['neighbor'] = switch.text
        lldp[eth]['neighbors'] << switch.text
        if eth == primary
          lldp[:parent] = switch.text
        end
      end
      interface.elements.each('chassis/capability') do |capability|
        next unless capability.attributes['type'] == 'Router'
        router = capability.attributes.fetch('enabled', 'off').to_s == 'on'
        lldp[eth]['router'] = router
        # Ignore linux hosts when setting the parent
        # VMs have a properly defined primary interface as such they are
        # able to detect there parent with the block above.  This use case is
        # for bare metal boxes that have linux VMs with ip_forwarding enabled and
        # ensures we only pick none linux devices as the parent i.e. switches
        if router && lldp[:parent].nil? && desc !~ (/Linux/)
          lldp[:parent] = lldp[eth]['neighbor']
        end
      end
      interface.elements.each('port') do |port|
        lldp[eth]['port'] = port.elements['id'].text
        lldp[eth]['descr'] = port.elements['descr'].text if port.elements['descr']
        lldp[eth]['mtu'] = port.elements['mfs'].text.to_i if port.elements['mfs']
      end

      next unless interface.elements['vlan']
      lldp[eth]['vlans'] = {'tagged_vlans' => []}
      interface.elements.each('vlan') do |vlan|
        if vlan.attributes.fetch('pvid', 'no').to_s == 'yes'
          lldp[eth]['vlans']['untagged_vlan'] = vlan.attributes['vlan-id'].to_i
        end
        lldp[eth]['vlans']['tagged_vlans'] << vlan.attributes['vlan-id'].to_i
      end
      if lldp[eth]['vlans'].key?('untagged_vlan')
        if lldp[eth]['vlans']['tagged_vlans'].length > 1
          lldp[eth]['vlans']['mode'] = 'tagged'
        else
          lldp[eth]['vlans'].delete('tagged_vlans')
          lldp[eth]['vlans']['mode'] = 'access'
        end
      else
        # not sure if we would ever hit this
        lldp[eth]['vlans']['mode'] = 'tagged-all'
      end
    end
    lldp
  end
end

Facter.add(:lldp_parent) do
  confine :kernel => %w{Linux FreeBSD OpenBSD}

  setcode do
    begin
      # Facter 3
      primary = Facter.value(:networking)['primary']
    rescue
      # fallback to our own implementation
      primary = Facter.value(:interface_primary)
    end

    begin
      Facter.value(:lldp)[primary]['neighbor']
    rescue
      nil
    end
  end
end

Facter.add(:lldp_neighbors) do
  confine :kernel => %w{Linux FreeBSD OpenBSD}
  confine do
    !Facter.value(:lldp).nil?
  end

  setcode do
    neighbors = []
    Facter.value(:lldp).each do |_, values|
      neighbor = values['neighbor']
      if neighbor
        neighbors.push(neighbor)
      end
    end

    neighbors
  end
end

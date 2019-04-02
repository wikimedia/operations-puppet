require 'facter'
require 'rexml/document'

Facter.add(:lldp) do
  confine :kernel => %w{Linux FreeBSD OpenBSD}
  confine do
    File.exists?('/usr/sbin/lldpctl')
  end

  setcode do
    lldp = {}
    data = Facter::Util::Resolution.exec('/usr/sbin/lldpctl -f xml')
    document = REXML::Document.new(data)

    document.elements.each('lldp/interface') do |interface|
      eth = interface.attributes['name']
      lldp[eth] = {}

      interface.elements.each('chassis/name') do |switch|
        lldp[eth]['neighbor'] = switch.text
      end
      interface.elements.each('port/id') do |port|
        lldp[eth]['port'] = port.text
      end
      interface.elements.each('vlan') do |vlan|
        lldp[eth]['vlan'] = vlan.text
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

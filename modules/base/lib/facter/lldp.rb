require 'facter'
require 'rexml/document'

if Facter.value('virtual') == 'physical' && File.exists?('/usr/sbin/lldpctl')

    lldppeers = nil

    data = Facter::Util::Resolution.exec('/usr/sbin/lldpctl -f xml')
    document = REXML::Document.new(data)
    document.elements.each('lldp/interface') do |iface|
        eth = iface.attributes['name']
        iface.elements.each('chassis/name') do |switch|
            Facter.add('lldppeer_%s' % eth) do
                confine :kernel => %w{Linux FreeBSD OpenBSD}
                setcode do
                    switch.text
                end
            end
            if lldppeers
                lldppeers = lldppeers + ',' + switch.text
            else
                lldppeers = switch.text
            end
        end
        iface.elements.each('port/descr') do |port|
            Facter.add('lldpswport_%s' % eth) do
                confine :kernel => %w{Linux FreeBSD OpenBSD}
                setcode do
                    port.text
                end
            end
        end
        iface.elements.each('port/id') do |port|
            Facter.add('lldpswportid_%s' % eth) do
                confine :kernel => %w{Linux FreeBSD OpenBSD}
                setcode do
                    port.text
                end
            end
        end
        # VLAN info is also reported by LLDP but for now not parsing it due to some
        # inconsistencies in reporting depending on vendor and lack of a use case
        # sample code is provided however
        # iface.elements.each('vlan') do |vlan|
        #    Facter.add('lldpswport_vlan_%s' % eth) do
        #        confine :kernel => %w{Linux FreeBSD OpenBSD}
        #        setcode do
        #            vlan.text
        #        end
        #    end
        # end
    end

    # Aggregate all the lldp peers on one single variable
    Facter.add('lldppeers') do
        confine :kernel => %w{Linux FreeBSD OpenBSD}
        setcode do
            lldppeers
        end
    end
end

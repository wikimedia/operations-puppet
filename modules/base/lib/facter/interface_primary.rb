# Copyright: 2017 Wikimedia Foundation, Inc.
#
# Fact: interface_primary
#
# Purpose: Determine the primary network interface
#
# Resolution:
#
#   Returns the primary network interface, i.e. the interface which is used
#   to reach the default gateway of the system.
#
#   Note that this is obsolete with recent version of facter (> 3) and the
#   networking structured fact.

require 'facter'
require 'json'

Facter.add('interface_primary') do
  confine :kernel => :linux
  setcode do
    # Pick the interface used to reach the default IPv4 gateway.  The IPv6 gw
    # may or may not be reachable through the same interface, so technically
    # this is "interface4_primary", but that's a corner-case that we currently
    # do not need to handle.
    gw_route = Facter::Util::Resolution.exec('ip -4 route list 0/0')
    /.* dev (?<intf>[^\s]+)( .*)?$/ =~ gw_route
    intf
  end
end

# Returns a hash with the v4 and v6 gateway addresses if any.
# Eg. { "ipv4"=>"10.64.48.1", "ipv6"=>"fe80::1" }
Facter.add('default_routes') do
  confine :kernel => :linux
  setcode do
    intf = Facter.fact('interface_primary').value
    default_routes = {}

    gw_route4 = Facter::Util::Resolution.exec('ip -4 route list 0/0')
    /.* via (?<v4gateway>[^\s]+) .*/ =~ gw_route4
    default_routes['ipv4'] = v4gateway
    gw_route6 = Facter::Util::Resolution.exec("ip -6 route list ::/0 dev #{intf}")
    /.* via (?<v6gateway>[^\s]+) .*/ =~ gw_route6
    default_routes['ipv6'] = v6gateway

    default_routes
  end
end

Facter.add('ipaddress') do
  confine :kernel => :linux
  has_weight 100
  setcode do
    intf = Facter.fact('interface_primary').value
    Facter.fact('ipaddress_' + intf).value
  end
end

Facter.add('ipaddress6') do
  confine :kernel => :linux
  has_weight 100
  setcode do
    ip = nil
    intf = Facter.fact('interface_primary').value
    ipv4_mapped = Facter.fact('ipaddress').value.gsub('.', ':')

    # Do not rely on ipaddress6_#{interface_primary}, as its underlying
    # implementation is unreliable and often wrong. Among other issues, it uses
    # ifconfig instead of iproute and does not filter out deprecated
    # (preferred_lft 0) addresses. Do our own parsing.
    ipout = Facter::Util::Resolution.exec("ip --oneline -6 address list dev #{intf}")
    ipout.each_line do |line|
      tmp_ip = line.split[3].split('/')[0]
      # If we have a mapped address use it, otherwise just keep facters default
      if tmp_ip.end_with?(ipv4_mapped)
        ip = tmp_ip
        break
      end
    end

    ip
  end
end
#
# copy the networking fact
networking = Facter.fact(:networking).value
# Clear the current fact if we dont do this the built in is always prefered
Facter[:networking].flush
Facter.add(:networking) do
  has_weight 100
  setcode do
    # We override the ip6 fact with the one we calculate above as ours is better
    # as it rejects slaac addresses. See comment under ipaddress6 fact for more detail
    networking['ip6'] = Facter.fact(:ipaddress6).value

    # remove k8s interfaces
    networking['interfaces'].reject! { |key, _| key.start_with?('cali', 'tap') || key == ('lo:LVS') }

    # Add additional network device info
    os_release = Facter.fact(:os).value['release']['major'].to_i
    # Skip if OS is stretch as iproute2 version in it does not support JSON output
    if os_release > 9
      net_links = JSON.parse(Facter::Util::Resolution.exec("ip --json -d link show"))
      net_links.each do |data|
        next unless networking['interfaces'].key?(data['ifname']) && data.key?("linkinfo")
        iface = networking['interfaces'][data['ifname']]
        if data['linkinfo'].key?("info_kind")
          iface['kind'] = data['linkinfo']['info_kind']
          if data['linkinfo']['info_kind'] == "vlan"
            iface['dot1q'] = data['linkinfo']['info_data']['id']
            iface['parent_link'] = data['link']
          end
        end
        if data['linkinfo']['info_slave_kind'] == "bridge"
          iface['parent_bridge'] = data['master']
        end
      end
    end

    networking
  end
end

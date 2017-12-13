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

    # Do not rely on ipaddress6_#{interface_primary}, as its underlying
    # implementation is unreliable and often wrong. Among other issues, it uses
    # ifconfig instead of iproute and does not filter out deprecated
    # (preferred_lft 0) addresses. Do our own parsing.
    ipout = Facter::Util::Resolution.exec("ip -6 address list dev #{intf}")
    ipout.each_line do |s|
      if s =~ %r{^\s*inet6 ([0-9a-f:]+)\/([0-9]+) scope global (?!deprecated)}
        ip = Regexp.last_match(1)
        break
      end
    end

    ip
  end
end

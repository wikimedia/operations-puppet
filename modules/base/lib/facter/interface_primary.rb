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
     gw_route = Facter::Util::Resolution.exec('ip -4 route list 0/0')
     /.* dev (?<intf>[^\s]+) .*/ =~ gw_route
     intf
  end
end

Facter.add('ipaddress_primary') do
  confine :kernel => :linux
  setcode do
    intf = Facter.fact('interface_primary').value
    Facter.fact('ipaddress_' + intf).value
  end
end

Facter.add('ipaddress6_primary') do
  confine :kernel => :linux
  setcode do
    intf = Facter.fact('interface_primary').value
    Facter.fact('ipaddress6_' + intf).value
  end
end

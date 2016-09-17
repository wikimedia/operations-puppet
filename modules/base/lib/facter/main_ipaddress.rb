# Copyright (c) 2016 Wikimedia Foundation, Inc.
# Author: Giuseppe Lavagetto <joe@wikimedia.org>
#
# Fact: main_ipaddress
#
# Purpose: extract the ip address we'll use for all practical purposes.
#
# Resolution:
#
#    We don't really expect this to be useful outside of the boundaries of our own
#    site.
Facter.add("main_ipaddress") do
  setcode do
    if Facter.value(:ipaddress_eth0)
      Facter.value(:ipaddress_eth0)
    elsif Facter.value(:ipaddress_bond0)
      Facter.value(:ipaddress_bond0)
    else
      Facter.value(:ipaddress)
    end
  end
end

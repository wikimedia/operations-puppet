# SPDX-License-Identifier: Apache-2.0
# @summary eturns the first usable address of a cidr network
#
Puppet::Functions.create_function(:'wmflib::cidr_first_address') do
  # @param ip IPv6 or IPv4 address in CIDR notation
  # @return IPv6 or IPv4 network/net address
  # @example calling the function
  #   wmflib::cidr_first_address('2001:DB8::/32')
  dispatch :cidr_to_network do
    param 'Variant[Stdlib::IP::Address::V4::CIDR,Stdlib::IP::Address::V6::CIDR]', :ip
    return_type 'Variant[Stdlib::IP::Address::V4::Nosubnet,Stdlib::IP::Address::V6::Nosubnet]'
  end

  def cidr_to_network(ip)
    IPAddr.new(ip).to_range.first(2)[1].to_s
  end
end

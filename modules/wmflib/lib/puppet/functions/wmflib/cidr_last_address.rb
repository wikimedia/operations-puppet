# SPDX-License-Identifier: Apache-2.0
# @summary returns the last usable address of a cidr network
#
Puppet::Functions.create_function(:'wmflib::cidr_last_address') do
  # @param ip IPv6 or IPv4 address in CIDR notation
  # @return IPv6 or IPv4 network/net address
  # @example calling the function
  #   wmflib::cidr_last_address('192.168.2.0/24')
  #   => '192.168.2.255'
  #   wmflib::cidr_last_address('fe80::800:27ff:fe00:0/64')
  #   => 'fe80::ffff:ffff:ffff:ffff'
  dispatch :cidr_last_address do
    param 'Variant[Stdlib::IP::Address::V4::CIDR,Stdlib::IP::Address::V6::CIDR]', :ip
    return_type 'Variant[Stdlib::IP::Address::V4::Nosubnet,Stdlib::IP::Address::V6::Nosubnet]'
  end

  def cidr_last_address(cidr_s)
    # @param cidr_s
    #   The cidr to be inspected
    #
    # @return [str]
    #   The String representation of the last address in the subnet
    # @note
    #   This functions uses bitwise manipulation to compute the mask and the last
    #   address in the subnet. The simple strategy of using cidr.to_range.last
    #   would loop over all addresses, which is computationally expensive for large
    #   IPv6 subnets (as in minutes), whereas this is instantaneous.
    cidr = IPAddr.new(cidr_s)
    mask_bit_length = cidr.ipv6? ? 128 : 32
    shifted_mask = 1 << mask_bit_length
    mask = shifted_mask - (1 << (mask_bit_length - cidr.prefix))
    last_address = IPAddr.new(cidr | (~mask & (shifted_mask - 1)), cidr.family)
    last_address.to_s
  end
end

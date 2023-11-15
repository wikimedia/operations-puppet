# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'ipaddr'

Puppet::Functions.create_function(:'wmflib::cidr2mask') do
  # @summary
  #   Convert a CIDR value to its associated netmask
  # @example
  #   wmflib::cidr2mask("192.168.2.0/24")
  #   => "255.255.255.0"
  #   wmflib::cidr2mask("2620:0:861:1::/64")
  #   => "ffff:ffff:ffff:ffff::"
  # @param cidr
  #   The cidr to be converted
  #
  # @return [str]
  #   The String representation of the object
  dispatch :cidr2mask do
    param 'String', :cidr
  end

  def cidr2mask(cidr_s)
    # @param cidr_s
    #   The cidr to be converted
    #
    # @return [str]
    #   The String representation of the object
    cidr = IPAddr.new(cidr_s)
    IPAddr.new(cidr.instance_variable_get(:@mask_addr), cidr.family).to_s
  end
end

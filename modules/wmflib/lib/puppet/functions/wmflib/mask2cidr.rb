# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'ipaddr'

# @summary
#   Convert an Subnetmask to the cidr value
#

Puppet::Functions.create_function(:'wmflib::mask2cidr') do
  dispatch :mask2cidr do
    param 'Stdlib::IP::Address', :mask
  end

  # @param object
  #   The object to be converted
  #
  # @return [int]
  #   The String representation of the object
  def mask2cidr(mask)
    IPAddr.new(mask).to_i.to_s(2).count("1")
  end
end

# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

Puppet::Functions.create_function(:'ssh::ssh_ca_key_available') do
  dispatch :ssh_ca_key_available do
  end

  def ssh_ca_key_available
    File.exist?('/etc/ssh/ca')
  end
end

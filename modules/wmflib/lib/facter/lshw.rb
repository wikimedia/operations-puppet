# SPDX-License-Identifier: Apache-2.0
require 'facter'
require 'json'

Facter.add(:lshw) do
  confine :kernel => 'Linux'
  confine :is_virtual => false
  # Only make this available if lshw is installed on the system.
  confine do
    File.exist?('/usr/bin/lshw')
  end
  # Additionally confine to only Traffic hosts for now (cp/dns), excluding LVS.
  confine do
    Facter.value(:networking)['hostname'].match?(/^(cp|dns)[1-9][0-9]{3}$/)
  end

  setcode do
    lshw = {}

    lshw_memory = JSON.parse(Facter::Util::Resolution.exec('/usr/bin/lshw -class memory -json'))
    # We only want to get information about memory slots with DIMMs and those
    # are the ones with id bank:n and size.
    lshw[:memory] = lshw_memory.select { |hash| hash['id'].start_with?('bank') && hash.key?('size') }

    lshw
  end
end

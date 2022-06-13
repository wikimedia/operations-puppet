# SPDX-License-Identifier: Apache-2.0
require 'facter'
require 'json'

# return a hash of unmounted volumes and their sizes.
Facter.add(:block_devices) do
  confine :kernel => 'Linux'

  setcode do
    unused = []
    lsblk_raw = Facter::Core::Execution.exec("/bin/lsblk -Jbl -o NAME,TYPE,MOUNTPOINT,UUID,SIZE,FSTYPE")
    lsblk = JSON.parse(lsblk_raw)
    lsblk['blockdevices'].each do |device|
      unused.push({'dev' => device['name'],
                   'type' => device['type'],
                   'size' => device['size'].to_i,
                   'uuid' => device['uuid'],
                   'mountpoint' => device['mountpoint'],
                   'fstype' => device['fstype']})
    end
    unused
  end
end

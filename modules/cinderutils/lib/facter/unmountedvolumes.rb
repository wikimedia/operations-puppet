require 'facter'
require 'json'

# return a hash of unmounted volumes and their sizes.
Facter.add(:unmounted_volumes) do
  confine :kernel => 'Linux'

  setcode do
    unused = {}
    lsblk_raw = Facter::Core::Execution.exec("lsblk -Jb")
    lsblk = JSON.parse(lsblk_raw)
    lsblk['blockdevices'].each do |device|
      next unless device['type'] == 'disk'
      next if device['children']
      next if device['mountpoint']
      unused[device['name']] = device['size'].to_i
    end
    unused
  end
end

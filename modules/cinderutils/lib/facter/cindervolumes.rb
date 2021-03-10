require 'facter'
require 'json'

# return a hash of unmounted volumes and their sizes.
Facter.add(:cinder_volumes) do
  confine :kernel => 'Linux'

  setcode do
    unused = []
    lsblk_raw = Facter::Core::Execution.exec("/bin/lsblk -Jb -o NAME,TYPE,MOUNTPOINT,UUID,SIZE")
    lsblk = JSON.parse(lsblk_raw)
    lsblk['blockdevices'].each do |device|
      next unless device['type'] == 'disk'
      next if device['children']
      unused.append({'dev' => device['name'], 'size' => device['size'].to_i, 'uuid' => device['uuid'], 'mountpoint' => device['mountpoint']})
    end
    unused
  end
end

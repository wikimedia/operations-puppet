require 'facter'

Facter.add(:disk_type) do
  confine :kernel => 'Linux'
  setcode do
    virtual = Facter.fact('virtual').value
    disk_type = {}
    Facter.fact('disks').value.keys.each do |disk|
      if virtual == 'physical'
        path = File.join('/sys/block', disk, 'queue/rotational')
        rotational = File.read(path).strip
        type = rotational == '0' ? 'ssd' : 'hdd'
      else
        type = 'virtual'
      end
      disk_type[disk] = type
    end
    disk_type
  end
end

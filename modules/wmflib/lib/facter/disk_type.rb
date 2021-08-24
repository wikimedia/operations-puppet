require 'facter'

Facter.add(:disk_type) do
  confine :kernel => 'Linux'
  base_dir = '/sys/block'

  disk_type = {}
  Facter.fact('disks').value.keys.each{ |disk| disk_type.merge!(disk => {}) }
  virtual = Facter.fact('virtual').value
  setcode do
    disk_type.each do |disk, value|
      if virtual == 'physical'
        type = File.read(File.join(base_dir, disk, 'queue/rotational')).strip
        value[:type] = type == '0' ? 'ssd' : 'hdd'
      else
        value[:type] = 'virtual'
      end
    end
    disk_type
  end
end

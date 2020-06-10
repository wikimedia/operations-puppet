require 'facter'

cpu_details = {
  'vulnerabilities' => {},
  'scaling_governor' => false,
  'scaling_driver' => false,
  'model' => nil,
  'family' => nil,
  'flags' => [],
  'bugs' => [],
  'cpus' => {}
}
Facter.add(:cpu_details) do
  confine :kernel => 'Linux'
  confine do
    # File.directory?('/sys/devices/system/cpu/vulnerabilities')
    File.file?('/proc/cpuinfo')
  end
  setcode do
    File.foreach('/proc/cpuinfo') do |line|
      if /^(:?cpu\s+)?(?<key>model|family)\s+:\s+(?<value>\d+)/ =~ line
        cpu_details[key] = key == 'model' ? value.to_i.to_s(16) : value
      end
      if /^(?<key>flags|bugs)\s+:\s+(?<value>[\w\s]+)/ =~ line
        cpu_details[key] = value.split(' ')
      end
      break if cpu_details['model'] && cpu_details['family'] && !cpu_details['flags'].empty? && !cpu_details['bugs'].empty?
    end

    Dir.foreach('/sys/devices/system/cpu/vulnerabilities') do |vuln|
      next if %w{. ..}.include? vuln
      cpu_details['vulnerabilities'][vuln] = File.read(
        "/sys/devices/system/cpu/vulnerabilities/#{vuln}"
      ).strip
    end
    Dir.glob('/sys/devices/system/cpu/cpu*').each do |cpu_dir|
      cpu_id = File.basename(cpu_dir)
      governor_file = File.join(cpu_dir, 'cpufreq/scaling_governor')
      driver_file = File.join(cpu_dir, 'cpufreq/scaling_driver')
      cpu_details['cpus'][cpu_id] = {
        'scaling_governor' => false,
        'scaling_driver' => false,
      }
      if File.file?(governor_file)
        governor_content = File.read(governor_file).strip
        cpu_details['cpus'][cpu_id]['scaling_governor'] = governor_content
        cpu_details['scaling_governor'] = governor_content unless cpu_details['scaling_governor']
      end
      next unless File.file?(driver_file)
      driver_content = File.read(driver_file).strip
      cpu_details['cpus'][cpu_id]['scaling_driver'] = driver_content
      cpu_details['scaling_driver'] = driver_content unless cpu_details['scaling_driver']
    end
    cpu_details
  end
end
Facter.add(:cpu_scaling_governor) do
  setcode { cpu_details['scaling_governor'] }
end
Facter.add(:cpu_scaling_driver) do
  setcode { cpu_details['scaling_driver'] }
end
Facter.add(:cpu_flags) do
  setcode { cpu_details['flags'] }
end
Facter.add(:cpu_model) do
  setcode { cpu_details['model'] }
end

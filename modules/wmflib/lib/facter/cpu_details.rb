require 'facter'

cpu_details = {
  'vulnerabilities' => {},
  'scaling_governor' => false,
  'scaling_driver' => false,
  'cpus' => {}
}
Facter.add(:cpu_details) do
  confine :kernel => 'Linux'
  confine do
    File.directory?('/sys/devices/system/cpu/vulnerabilities')
  end
  setcode do
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

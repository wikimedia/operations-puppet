require 'facter'

Facter.add(:cpu_details) do
  confine :kernel => 'Linux'
  cpu_details = {
    'vulnerabilities' => {},
  }
  Dir.foreach('/sys/devices/system/cpu/vulnerabilities') do |vuln|
    next if %w{. ..}.include? vuln
    cpu_details['vulnerabilities'][vuln] = File.read(
      "/sys/devices/system/cpu/vulnerabilities/#{vuln}"
    )
  end
  setcode { cpu_details }
end

require 'facter'

Facter.add(:cpu_details) do
  confine :kernel => 'Linux'
  confine do
    File.directory?('/sys/devices/system/cpu/vulnerabilities')
  end
  setcode do
    cpu_details = {
      'vulnerabilities' => {},
    }
    Dir.foreach('/sys/devices/system/cpu/vulnerabilities') do |vuln|
      next if %w{. ..}.include? vuln
      cpu_details['vulnerabilities'][vuln] = File.read(
        "/sys/devices/system/cpu/vulnerabilities/#{vuln}"
      )
    end
    cpu_details
  end
end

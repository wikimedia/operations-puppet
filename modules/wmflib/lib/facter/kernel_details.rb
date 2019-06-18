require 'facter'

# this is a list of sysctl_settings we care about
# we can add more as needed
sysctl_settings = [
  'net.ipv4.tcp_min_snd_mss',
]
Facter.add(:kernel_details) do
  confine :kernel => 'Linux'
  confine do
    File.exist?('/bin/uname')
  end
  kernel_details = {}
  kernel_details['release'] =  Facter::Util::Resolution.exec('/bin/uname -r')
  kernel_details['version'] =  Facter::Util::Resolution.exec('/bin/uname -v')
  kernel_details['sysctl_settings'] = {}
  sysctl_settings.each do |sysctl_setting|
    kernel_details['sysctl_settings'][sysctl_setting] = File.file?("/proc/sys/#{sysctl_setting.gsub('.', '/')}")
  end
  setcode { kernel_details }
end

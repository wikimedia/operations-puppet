require 'facter'

# this is a list of sysctl_settings we care about
# we can add more as needed
sysctl_int_settings = [
  'net.ipv4.tcp_min_snd_mss',
]
sysctl_bool_settings = [
  'kernel.unprivileged_userns_clone',
]
kernel_details = {}
Facter.add(:kernel_details) do
  confine :kernel => 'Linux'
  confine do
    File.exist?('/bin/uname')
  end
  kernel_details['release'] =  Facter::Util::Resolution.exec('/bin/uname -r')
  kernel_details['version'] =  Facter::Util::Resolution.exec('/bin/uname -v')
  kernel_details['sysctl_settings'] = {}
  sysctl_int_settings.each do |sysctl_setting|
    proc_file = "/proc/sys/#{sysctl_setting.gsub('.', '/')}"
    if File.file?(proc_file)
      kernel_details['sysctl_settings'][sysctl_setting] = File.read(proc_file).strip.to_i
    end
  end
  sysctl_bool_settings.each do |sysctl_setting|
    proc_file = "/proc/sys/#{sysctl_setting.gsub('.', '/')}"
    if File.file?(proc_file)
      kernel_details['sysctl_settings'][sysctl_setting] = !File.read(proc_file).strip.to_i.zero?
    end
  end
  setcode { kernel_details }
end
# Also add this as a legacy fact so its avalible to cumin
Facter.add(:kernel_unprivileged_userns_clone) do
  confine do
    kernel_details.fetch('sysctl_settings', {}).key?('kernel.unprivileged_userns_clone')
  end
  setcode { kernel_details['sysctl_settings']['kernel.unprivileged_userns_clone'] }
end

require 'facter'

Facter.add(:has_ipmi) do
  confine :kernel => %w{Linux FreeBSD OpenBSD}
  confine :virtual => 'physical'
  confine do
    File.exists?('/usr/sbin/dmidecode')
  end

  setcode do
    # SMBIOS spec defines DMI type 38 as "IPMI Device"
    dmi = Facter::Util::Resolution.exec('dmidecode --type 38')
    !(dmi =~ /IPMI Device Information/).nil?
  end
end

Facter.add(:ipmi_lan) do
  confine :has_ipmi => true
  confine do
    File.exists?('/usr/sbin/bmc-config') || File.exists?('/usr/bin/ipmitool')
  end

  setcode do
    ipmi_lan = {}
    if File.exists?('/usr/sbin/bmc-config')
      cmd = '/usr/sbin/bmc-config -o -S Lan_Conf'
    else
      cmd = '/usr/bin/ipmitool lan print'
    end
    Facter::Util::Resolution.exec(cmd).each_line do |line|
      # compatible with both bmc-config and ipmitool's output
      next unless /^\s*(?<key>[^#].+[^\s])\s+:?\s(?<value>[^\s]+)/ =~ line
      # bmc-config uses underscores, ipmitool uses spaces; handle both
      case key.gsub(' ', '_')
      when 'IP_Address_Source' then
        unless value == 'Static'
          ipmi_lan = nil
          break
        end
      when 'IP_Address' then
        ipmi_lan['ipaddress'] = value
      when 'MAC_Address' then
        ipmi_lan['macaddress'] = value.downcase
      when 'Subnet_Mask' then
        ipmi_lan['netmask'] = value
      when 'Default_Gateway_IP_Address', 'Default_Gateway_IP' then
        ipmi_lan['gateway'] = value
      end
    end
    ipmi_lan
  end
end

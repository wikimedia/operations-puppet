require 'facter'

Facter.add(:has_ipmi) do
  confine :kernel => %w{Linux FreeBSD OpenBSD}
  confine :virtual => 'physical'
  confine do
    File.exists?('/usr/sbin/bmc-config')
  end

  setcode do
    # SMBIOS spec defines DMI type 38 as "IPMI Device"
    dmi = Facter::Util::Resolution.exec('dmidecode --type 38')
    !(dmi =~ /IPMI Device Information/).nil?
  end
end

Facter.add(:ipmi_lan) do
  confine :has_ipmi => true

  setcode do
    ipmi_lan = {}
    conf = Facter::Util::Resolution.exec('bmc-config -o -S Lan_Conf')
    conf.each_line do |line|
      next unless /^\s+(?<key>[^#][^\s]+)\s+(?<value>[^\s]+)/ =~ line
      case key
      when 'IP_Address_Source' then
        unless value == 'Static'
          ipmi_lan = nil
          break
        end
      when 'IP_Address' then
        ipmi_lan['ipaddress'] = value
      when 'MAC_Address' then
        ipmi_lan['macaddress'] = value
      when 'Subnet_Mask' then
        ipmi_lan['netmask'] = value
      when 'Default_Gateway_IP_Address' then
        ipmi_lan['gateway'] = value
      end
    end
    ipmi_lan
  end
end

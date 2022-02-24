require 'facter'

firmware = {
  'idrac' => nil,
  'ilo' => nil,
}
Facter.add(:firmware_ilo) do
  confine :kernel => 'Linux'
  confine :is_virtual => false
  confine :manufacturer => %w{HP HPE}
  setcode do
    if Facter::Core::Execution.which('dmidecode')
      # https://support.hpe.com/hpesc/public/docDisplay?docId=kc0120268en_us&docLocale=en_US
      bios_info = Facter::Core::Execution.execute('dmidecode -t bios')
      ilo_matcher = /\s+Firmware\s+Revision:\s+(?<ilo_version>.+)/
      if matches = bios_info.match(ilo_matcher) # rubocop:disable AssignmentInCondition
          firmware['ilo'] = matches['ilo_version']
      end
    end
    firmware['ilo']
  end
end
Facter.add(:firmware_idrac) do
  confine :kernel => 'Linux'
  confine :is_virtual => false
  confine :manufacturer => 'Dell Inc.'
  setcode do
    if Facter::Core::Execution.which('ipmi-oem')
      matcher = /iDRAC\s+Firmware\s+Version\s+:\s+(?<idrac_version>(?:\d+\.){3}\d+)/
      idrac_info = Facter::Core::Execution.execute('ipmi-oem dell get-system-info idrac-info')
      if matches = idrac_info.match(matcher) # rubocop:disable AssignmentInCondition
        firmware['idrac'] = matches['idrac_version']
      end
    end
    firmware['idrac']
  end
end
Facter.add(:firmware) do
  confine :kernel => 'Linux'
  confine :is_virtual => false
  setcode do
    # TODO: use the following once everything is on ruby 2.5
    # firmware.compact!
    firmware.reject! {|_k, v| v.nil?}
  end
end

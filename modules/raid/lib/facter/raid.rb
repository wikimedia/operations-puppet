# SPDX-License-Identifier: Apache-2.0
require 'facter'

Facter.add('raid_mgmt_tools') do
  # ref: http://pci-ids.ucw.cz/v2.2/pci.ids
  # Run sudo lspci -nn to add missing PCI IDs, the combination of vendor ID and device ID is printed in []
  pci_ids = {
    '9005028f' => 'ssacli',   # Smart Storage PQI 12G SAS/PCIe 3
    '100010e2' => 'perccli',  # Perc 750
    '103c3239' => 'hpssacli', # Hewlett-Packard Company Smart Array Gen9 Controllers
    '1000005d' => 'megaraid', # LSI Logic / Symbios Logic MegaRAID SAS-3 3108
    '100010e2' => 'megaraid', # Broadcom / LSI MegaRAID 12GSAS/PCIe Secure SAS39x
  }
  setcode do
    raids = []

    File.open('/proc/bus/pci/devices').each do |line|
      words = line.split
      raids.push(pci_ids[words[1]]) if pci_ids.key?(words[1])
    end

    if File.exists?('/proc/mdstat') && File.open('/proc/mdstat').grep(/md\d+\s+:\s+active/)
      raids.push('mdadm')
    end
  end
end

Facter.add('raid') do
  confine :kernel => :linux
  # ref: http://pci-ids.ucw.cz/v2.2/pci.ids
  pci_ids = {
    # TODO: this is a bit of a hack the driver is still hpsa, but we need to use the newer ssacli tool
    '9005028f' => 'ssacli' # Smart Storage PQI 12G SAS/PCIe 3
  }
  setcode do
    raids = []

    File.open('/proc/bus/pci/devices').each do |line|
      words = line.split
      raids.push(pci_ids[words[1]]) if pci_ids.key?(words[1])
    end

    if FileTest.exist?('/proc/mdstat')
      IO.foreach('/proc/mdstat') do |x|
        if x =~ /md[0-9]+ : active/
          raids.push('md')
          break
        end
      end
    end

    if FileTest.exist?('/dev/cciss/') || FileTest.exist?('/sys/module/hpsa/')
      raids.push('hpsa') unless raids.include?('ssacli')
    end

    if FileTest.exist?('/dev/megadev0') ||
       Dir.glob('/sys/bus/pci/drivers/megaraid_sas/00*').length > 0 # rubocop:disable Style/NumericPredicate
      raids.push('megaraid')
    end

    if FileTest.exist?('/dev/mpt0') ||
       FileTest.exist?('/proc/scsi/mptsas/0')
      raids.push('mpt')
    end

    raids.sort.uniq
  end
end

# Enable calling directly as a bypass for T251293
if $PROGRAM_NAME == __FILE__
  require 'json'
  puts JSON.dump({ :raid => Facter.value('raid') })
end

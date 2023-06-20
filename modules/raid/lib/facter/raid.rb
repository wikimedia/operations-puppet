# SPDX-License-Identifier: Apache-2.0
require 'facter'

Facter.add('raid_mgmt_tools') do
  # ref: http://pci-ids.ucw.cz/v2.2/pci.ids
  # Run sudo lspci -nn to add missing PCI IDs, the combination of vendor ID and device ID is printed in []
  pci_ids = {
    '9005028f' => 'ssacli',      # Smart Storage PQI 12G SAS/PCIe 3
    '100010e2' => 'perccli',     # Broadcom / LSI MegaRAID 12GSAS/PCIe Secure SAS39xx (sold as Perc H750)
    '103c3239' => 'hpsa',        # Hewlett-Packard Company Smart Array Gen9 Controllers
    '1000005d' => 'megaraid',    # LSI Logic / Symbios Logic MegaRAID SAS-3 3108, also shows up as
                                 # Broadcom / LSI MegaRAID SAS-3 3108 [Invader]
    '100000cf' => 'megaraid',    # Broadcom / LSI MegaRAID SAS-3 3324 [Intruder] (rev 01)
    '10000016' => 'megaraid',    # Broadcom / LSI MegaRAID Tri-Mode SAS3508
    '10000014' => 'megaraid',    # LSI Logic / Symbios Logic MegaRAID Tri-Mode SAS3516
    '10000097' => 'perccli_hba', # Broadcom / LSI SAS3008 PCI-Express Fusion-MPT SAS-3 (Sold as Perc HBA330 mini)
  }
  setcode do
    raids = []

    File.open('/proc/bus/pci/devices').each do |line|
      words = line.split
      raids.push(pci_ids[words[1]]) if pci_ids.key?(words[1])
    end

    if File.exists?('/proc/mdstat') && File.open('/proc/mdstat').grep(/md\d+\s+:\s+active/)
      raids.push('md')
    end
    raids.sort.uniq
  end
end

# Enable calling directly as a bypass for T251293, T320636
if $PROGRAM_NAME == __FILE__
  require 'json'
  puts JSON.dump({ :raid => Facter.value('raid_mgmt_tools') })
end

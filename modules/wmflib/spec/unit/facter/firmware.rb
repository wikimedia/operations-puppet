require_relative '../../../../../rake_modules/spec_helper'

dell_dmidecode_output = <<-DELL
# dmidecode 3.2
Getting SMBIOS data from sysfs.
SMBIOS 3.0 present.

Handle 0x0000, DMI type 0, 26 bytes
BIOS Information
        Vendor: Dell Inc.
        Version: 1.3.7
        Release Date: 02/09/2018
        Address: 0xF0000
        Runtime Size: 64 kB
        ROM Size: 0 MB
        Characteristics:
                ISA is supported
                PCI is supported
                PNP is supported
                BIOS is upgradeable
                BIOS shadowing is allowed
                Boot from CD is supported
                Selectable boot is supported
                EDD is supported
                Japanese floppy for Toshiba 1.2 MB is supported (int 13h)
                5.25"/360 kB floppy services are supported (int 13h)
                5.25"/1.2 MB floppy services are supported (int 13h)
                3.5"/720 kB floppy services are supported (int 13h)
                8042 keyboard services are supported (int 9h)
                Serial services are supported (int 14h)
                CGA/mono video services are supported (int 10h)
                ACPI is supported
                USB legacy is supported
                BIOS boot specification is supported
                Function key-initiated network boot is supported
                Targeted content distribution is supported
                UEFI is supported
        BIOS Revision: 1.3

Handle 0x0D00, DMI type 13, 22 bytes
BIOS Language Information
        Language Description Format: Long
        Installable Languages: 1
                en|US|iso8859-1
        Currently Installed Language: en|US|iso8859-1

DELL

hp_dmidecode_output = <<-HP
# dmidecode 3.0
Getting SMBIOS data from sysfs.
SMBIOS 3.2 present.
# SMBIOS implementations newer than version 3.0 are not
# fully supported by this version of dmidecode.

Handle 0x0003, DMI type 0, 26 bytes
BIOS Information
        Vendor: HPE
        Version: U32
        Release Date: 11/13/2019
        Address: 0xF0000
        Runtime Size: 64 kB
        ROM Size: 16384 kB
        Characteristics:
                PCI is supported
                PNP is supported
                BIOS is upgradeable
                BIOS shadowing is allowed
                ESCD support is available
                Boot from CD is supported
                Selectable boot is supported
                EDD is supported
                5.25"/360 kB floppy services are supported (int 13h)
                5.25"/1.2 MB floppy services are supported (int 13h)
                3.5"/720 kB floppy services are supported (int 13h)
                Print screen service is supported (int 5h)
                8042 keyboard services are supported (int 9h)
                Serial services are supported (int 14h)
                Printer services are supported (int 17h)
                CGA/mono video services are supported (int 10h)
                ACPI is supported
                USB legacy is supported
                BIOS boot specification is supported
                Function key-initiated network boot is supported
                Targeted content distribution is supported
                UEFI is supported
        BIOS Revision: 2.22
        Firmware Revision: 2.11

HP
ipmi_oem_output = <<-IPMI
IP Address             : 192.0.2.1
IP Configuration       : Static
iDRAC Firmware Version : 3.30.30.30 (76)
iDRAC Type             : Unknown
IPMI

describe Facter.fact(:firmware_bios).name do
  before do
    Facter.clear
  end
  context 'dmidecode not in path' do
    before do
      allow(Facter::Core::Execution).to receive(:which).and_call_original
      allow(Facter::Core::Execution).to receive(:which).with('dmidecode').and_return(false)
    end
    it { expect(Facter.fact(:firmware_bios).value).to eq(nil) }
  end
  context 'virtual machine should be nill' do
    before do
      allow(Facter::Core::Execution).to receive(:which).and_call_original
      allow(Facter::Core::Execution).to receive(:which).with('dmidecode').and_return(false)
      allow(Facter.fact(:is_virtual)).to receive(:value).and_return(true)
    end
    it { expect(Facter.value(:firmware_bios)).to eq(nil) }
  end
  {'1.3.7' => dell_dmidecode_output, 'U32' => hp_dmidecode_output}.each_pair do |version, output|
    context "detect version #{version}" do
      before do
        allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
        allow(Facter::Core::Execution).to receive(:which).and_call_original
        allow(Facter::Core::Execution).to receive(:which).with('dmidecode').and_return(true)
        allow(Facter::Core::Execution).to receive(:execute).and_call_original
        allow(Facter::Core::Execution).to receive(:execute).with('dmidecode -t bios').and_return(output)
        allow(Facter.fact(:is_virtual)).to receive(:value).and_return(false)
      end
      it { expect(Facter.value(:firmware_bios)).to eq(version) }
    end
  end
end
describe Facter.fact(:firmware_ilo).name do
  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
    allow(Facter::Core::Execution).to receive(:which).and_call_original
    allow(Facter::Core::Execution).to receive(:which).with('dmidecode').and_return(true)
    allow(Facter::Core::Execution).to receive(:execute).and_call_original
    allow(Facter::Core::Execution).to receive(:execute).with('dmidecode -t bios').and_return(hp_dmidecode_output)
    allow(Facter.fact(:is_virtual)).to receive(:value).and_return(false)
  end
  context 'no dmidecode' do
    before do
      allow(Facter::Core::Execution).to receive(:which).with('dmidecode').and_return(false)
    end
    it { expect(Facter.value(:firmware_ilo)).to eq(nil) }
  end
  context 'virtual machine should be nill' do
    before do
      allow(Facter.fact(:is_virtual)).to receive(:value).and_return(true)
    end
    it { expect(Facter.value(:firmware_ilo)).to eq(nil) }
  end
  context 'not HP' do
    before do
      allow(Facter.fact(:manufacturer)).to receive(:value).and_return('Foobar')
    end
    it { expect(Facter.value(:firmware_ilo)).to eq(nil) }
  end
  context 'detect version' do
    before do
      # https://github.com/rodjek/rspec-puppet/issues/673#issuecomment-379992614
      if Facter.fact(:manufacturer).nil?
         Facter.add(:manufacturer) { setcode { 'HP' } }
      else
        allow(Facter.fact(:manufacturer)).to receive(:value).and_return('HP')
      end
    end
    it { expect(Facter.value(:firmware_ilo)).to eq('2.11') }
  end
end
describe Facter.fact(:firmware_idrac).name do
  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
    allow(Facter::Core::Execution).to receive(:which).and_call_original
    allow(Facter::Core::Execution).to receive(:which).with('dmidecode').and_return(false)
    allow(Facter::Core::Execution).to receive(:which).with('ipmi-oem').and_return(true)
    allow(Facter::Core::Execution).to receive(:execute).and_call_original
    allow(Facter::Core::Execution).to receive(:execute).with('ipmi-oem dell get-system-info idrac-info')
      .and_return(ipmi_oem_output)
    allow(Facter.fact(:is_virtual)).to receive(:value).and_return(false)
  end
  context 'virtual machine should be nill' do
    before do
      allow(Facter.fact(:is_virtual)).to receive(:value).and_return(true)
    end
    it { expect(Facter.value(:firmware_idrac)).to eq(nil) }
  end
  context 'not Dell' do
    before do
      allow(Facter.fact(:manufacturer)).to receive(:value).and_return('Foobar')
    end
    it { expect(Facter.value(:firmware_idrac)).to eq(nil) }
  end
  context 'Detect version' do
    before do
      if Facter.fact(:manufacturer).nil?
         Facter.add(:manufacturer) { setcode { 'Dell Inc.' } }
      else
        allow(Facter.fact(:manufacturer)).to receive(:value).and_return('Dell Inc.')
      end
    end
    it { expect(Facter.value(:firmware_idrac)).to eq('3.30.30.30') }
  end
end

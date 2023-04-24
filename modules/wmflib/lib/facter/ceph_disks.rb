#!/usr/bin/ruby
# SPDX-License-Identifier: Apache-2.0
# Creates a ceph_disks fact if /usr/bin/perccli64 exists and the ceph-osd package is installed.
# It uses the perccli64 command to obtain the physical drive information for each slot
# then extracts the wwn, medium type, interface, and serial number for each drive.

require 'facter'
require 'json'

Facter.add(:ceph_disks) do
  confine :kernel => 'Linux'
  confine do
    Facter::Core::Execution.which('perccli64') &&
    Facter::Util::Resolution.which('dpkg-query') &&
    Facter::Util::Resolution.exec("dpkg-query -W --showformat='${Status}' ceph-osd") == "install ok installed"
  end
  setcode do
    result = {}
    perccli_info_raw = Facter::Core::Execution.exec("perccli64 /call show all J")
    unless perccli_info_raw.empty?
      perccli_info = JSON.parse(perccli_info_raw)
      perccli_info['Controllers'].each do |controller|
        id = controller['Response Data']['Basics']['SAS Address']
        result[id] = {
          status: controller['Command Status']['Status'],
          model: controller['Response Data']['Basics']['Model'],
          disks: Hash.new { |h, k| h[k] = {} }
        }
        next unless result[id][:status] == 'Success'

        controller['Response Data']['Physical Device Information'].each_pair do |drive_key, drive_config|
          next unless %r{Drive\s/(c\d+/e\d+/s\d+)} =~ drive_key
          if %r{^Drive\s/(c\d+/e\d+/s\d+)$} =~ drive_key
            drive_id = Regexp.last_match(1)
            controller, enclosure, slot = drive_id.tr('ces', '').split('/')
            result[id][:disks][drive_id]['controller'] = controller
            result[id][:disks][drive_id]['enclosure'] = enclosure
            result[id][:disks][drive_id]['slot'] = slot
            result[id][:disks][drive_id]['medium'] = drive_config[0]['Med']
            result[id][:disks][drive_id]['interface'] = drive_config[0]['Intf']
          end

          next unless drive_key.end_with?('- Detailed Information')
          drive_config.each_pair do |section_key, section_config|
            next unless %r{Drive\s/(c\d+/e\d+/s\d+)\sDevice\sattributes} =~ section_key
            drive_id = Regexp.last_match(1)
            result[id][:disks][drive_id]['wwn'] = section_config['WWN']
            result[id][:disks][drive_id]['serial'] = section_config['SN']
          end
        end
      end
    end
    result
  end
end

if $PROGRAM_NAME == __FILE__
  puts JSON.dump(Facter.value('ceph_disks'))
end

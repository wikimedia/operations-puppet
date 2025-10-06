# SPDX-License-Identifier: Apache-2.0
require 'facter'

Facter.add('swift_disks') do
  setcode do
    swift_disks = { }
    devices = Dir["/dev/disk/by-path/*"].map {|f| f.split('/')[-1]  }
    swift_disks[:accounts] = devices.select {|d| d.scan(/(ata-\d+\.\d+|scsi-\d+:\d+:\d+:\d+)-part4/).any? }.sort
    swift_disks[:container] = devices.select {|d| d.scan(/(ata-\d+\.\d+|scsi-\d+:\d+:\d+:\d+)-part5/).any? }.sort
    ssds = swift_disks[:accounts].map { |d| d[0...-8] }
    # disks may not be paritioned so we just get the route disk for this
    # This may be confusing need to check
    swift_disks[:objects] = devices.reject { |d| d.start_with?(*ssds) || d =~ (/-part[1-9]?$/) }.sort
    swift_disks
  end
end

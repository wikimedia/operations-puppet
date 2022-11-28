# SPDX-License-Identifier: Apache-2.0
require 'facter'

Facter.add('swift_disks') do
  setcode do
    swift_disks = { }
    devices = Dir["/dev/disk/by-path/*"].map {|f| f.split('/')[-1]  }
    swift_disks[:accounts] = devices.select {|d| d.end_with?('-part4') }.sort
    swift_disks[:container] = devices.select {|d| d.end_with?('-part5') }.sort
    ssds = swift_disks[:accounts].map { |d| d[0...-6] }
    # disks may not be paritioned so we just get the route disk for this
    # This may be confusing need to check
    swift_disks[:objects] = devices.reject { |d| d.start_with?(*ssds) || d =~ (/-part[1-9]$/) }.sort
    swift_disks
  end
end

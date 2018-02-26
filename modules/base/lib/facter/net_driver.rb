# net_driver.rb - network interface driver names
#
# Copyright 2018 Brandon Black
# Copyright 2018 Wikimedia Foundation, Inc.
#
# Sometimes, our puppetization only supports certain advanced network features
# when using certain classes of network hardware.  The driver name is a common
# case used to differentiate this, e.g. currently some optimizations we've only
# factored out to work correctly on 'bnx2x' -driven cards.

require 'facter'
require 'pathname'

Facter.add('net_driver') do
  setcode do
    net_d = {}
    Pathname.glob('/sys/class/net/*').sort.each do |d|
      dev = d.to_s.split('/')[4]
      driver_link = "#{d}/device/driver/module"
      if File.exist?(driver_link)
          net_d[dev] = File.basename(File.readlink(driver_link))
      end
    end
    net_d
  end
end

# net_driver.rb - network interface driver names
#
# Copyright 2018 Brandon Black
# Copyright 2018 Wikimedia Foundation, Inc.
#
# Sometimes, our puppetization only supports certain advanced network features
# when using certain classes of network hardware.  The driver name is a common
# case used to differentiate this, e.g. currently some optimizations we've only
# factored out to work correctly on 'bnx2x' -driven cards.
# The interface speed and duplex are also reported.
#
# The returned fact is a hash of hashes of the form:
# {"eth0"=>{"driver"=>"bnx2x", "speed"=>10000, "duplex"=>"full"}}

require 'facter'
require 'pathname'

Facter.add('net_driver') do
  setcode do
    net_d = {}
    Pathname.glob('/sys/class/net/*').sort.each do |d|
      dev = d.to_s.split('/')[4]
      driver_link = "#{d}/device/driver/module"

      if File.exist?(driver_link)
        net_d[dev] = {}
        net_d[dev]['driver'] = File.basename(File.readlink(driver_link))

        speed_file = "#{d}/speed"
        if File.exist?(speed_file)
          net_d[dev]['speed'] = File.read(speed_file).to_i
        end

        duplex_file = "#{d}/duplex"
        if File.exist?(duplex_file)
          net_d[dev]['duplex'] = File.read(duplex_file).strip
        end
      end
    end
    net_d
  end
end

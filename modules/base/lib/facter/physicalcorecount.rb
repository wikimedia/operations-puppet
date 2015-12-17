# physicalcorecount isn't fooled by hyperthread siblings

require 'facter'
require 'pathname'

Facter.add("physicalcorecount") do
    setcode do
        Pathname::glob('/sys/devices/system/cpu/cpu[0-9]*/topology/thread_siblings_list').map{|x|
            File.open(x,'r').read.split(',')[0]
        }.sort.uniq.count
    end
end

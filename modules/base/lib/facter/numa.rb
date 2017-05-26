# Gives NUMA topology, at least for CPUs and network interfaces.
# Network interfaces are not always reported by the kernel as attached to a
# specific NUMA node for a variety of reasons: virtual/software interfaces,
# certain single-node hardware configurations, and even in some cases ethernet
# cards plugged into multi-node systems.  For ease-of-use reasons, any network
# interface the kernel doesn't indicate as attached to a single specific node
# is assigned to all nodes in the output here, as shown for "lo" in the example
# below:
#
# numa = {
#    "node_count" => 2,
#    "node_to_cpu" => {
#        0 => [0, 2, 4, 6, 8, 10],
#        1 => [1, 3, 5, 7, 9, 11],
#    },
#    "node_to_device" => {
#        0 => ["eth0", "lo"],
#        1 => ["eth1", "lo"],
#    },
#    "cpu_to_node" => {
#        0  => 0,
#        2  => 0,
#        4  => 0,
#        6  => 0,
#        8  => 0,
#        10 => 0,
#        1  => 1,
#        3  => 1,
#        5  => 1,
#        7  => 1,
#        9  => 1,
#        11 => 1,
#    },
#    "device_to_node" => {
#        "eth0" => [0],
#        "eth1" => [1],
#        "lo"   => [0,1],
#    },
# }
#

require 'facter'
require 'pathname'

Facter.add("numa") do
    setcode do
        output = Hash.new()
        output['node_to_cpu'] = Hash.new()
        output['node_to_device'] = Hash.new()
        output['cpu_to_node'] = Hash.new()
        output['device_to_node'] = Hash.new()
        nodes = Pathname::glob('/sys/devices/system/node/node[0-9]*').map{|n| /([0-9]+)$/.match(n.to_s)[0].to_i}.sort
        output['node_count'] = nodes.length
        nodes.each do |n|
            output['node_to_device'][n] = Array.new()
            output['node_to_cpu'][n] = Pathname::glob("/sys/devices/system/node/node#{n}/cpu[0-9]*").map{|c| /([0-9]+)$/.match(c.to_s)[0].to_i}.sort
            output['node_to_cpu'][n].each do |c|
                output['cpu_to_node'][c] = n
            end
        end
        Pathname::glob('/sys/class/net/*').each do |d|
            dev = d.to_s.split('/')[4]
            nodefile = "#{d}/device/numa_node"
            raw_node = -1
            if File.exists?(nodefile)
                raw_node = File.open(nodefile,'r').read().to_i
            end
            if raw_node < 0
                dev_nodes = nodes
            else
                dev_nodes = [raw_node]
            end
            output['device_to_node'][dev] = dev_nodes
            dev_nodes.each do |dev_node|
                output['node_to_device'][dev_node].push(dev)
            end
        end
        output
    end
end

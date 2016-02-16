# == Function: redis_add_replica ($data, $my_ip, $shards, $primary_dc)
#
# Get which server/port combination, if any, should the redis
# instances on the current node replicate from.
# This is added to $data in the format used by $redis::instance::map
#
module Puppet::Parser::Functions
  newfunction(:redis_add_replica, :type => :rvalue, :arity => 4) do |args|
    data, ip, shards, masterdc = args
    site = compiler.topscope.lookupvar('site')
    if masterdc == site
      # We DO NOT want a return value if we're in the master dc
      return data
    end
    # Read the data structure
    shards[site].each do |name, v|
      next unless v['host'] == ip
      master = shards[masterdc][name]
      data[v['port']] ||= {}
      data[v['port']]["slaveof"] = "#{master['host']} #{master['port']}"
    end
    data
  end
end

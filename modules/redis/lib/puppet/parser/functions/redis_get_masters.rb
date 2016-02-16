# == Function: redis_get_instances ($my_ip, $shards, $primary_dc)
#
# Returns the list of ports on which there should be a redis instance to
# listen to
#
module Puppet::Parser::Functions
  newfunction(:redis_get_masters, :type => :rvalue, :arity => 3) do |args|
    ip = args[0]
    shards = args[1]
    masterdc = args[2]
    replica_map = {}
    site = compiler.topscope.lookupvar('site')
    if masterdc == site
      # We DO NOT want a return value if we're in the master dc
      return {}
    end
    # Read the data structure
    shards[site].each do |name, data|
      if data['host'] == ip
        master = shards[masterdc][name]
        replica_map[data['port']] = "#{master['host']} #{master['port']}"
      end
    end
    replica_map
  end
end

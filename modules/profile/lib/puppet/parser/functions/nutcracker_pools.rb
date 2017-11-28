module Puppet::Parser::Functions
  newfunction(:nutcracker_pools, :type => :rvalue, :arity => 4, :doc => <<-EOS
  Given a list of redis pools, memcached pools, and base settings for both,
  extracts a server list that is then fed to class nutcracker.
  EOS
    ) do |args|
    if args.size < 4
      raise(Puppet::ParseError, "nutcracker_pools: 4 arguments needed, (#{args.size} given)")
    end
    redis, memc, redis_settings, memc_settings = args

    pools = {}
    if redis.is_a?(Hash)
      redis.keys.each do |k|
        if pools.include?(k)
          raise(Puppet::ParseError, "Pool #{k} already defined")
        end
        pools[k] = redis_settings.merge(redis[k])
      end
    end
    if memc.is_a?(Hash)
      memc.keys.each do |k|
        if pools.include?(k)
          raise(Puppet::ParseError, "Pool #{k} already defined")
        end
        pools[k] = memc_settings.merge(memc[k])
      end
    end

    pools
  end
end

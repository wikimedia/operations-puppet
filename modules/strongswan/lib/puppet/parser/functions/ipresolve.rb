# == Function: ipresolve( string $name_to_resolve, bool $ipv6 = false)
#
# Performs a name resolution (for A AND AAAA records only) and returns
# an hash of arrays.
#
# Takes one or more names to resolve, and returns an array of all the
# A or AAAA records found. The resolution is actually only done when
# the ttl has expired.
#
require 'resolv'

class DNSCacheEntry
  def new(address, ttl)
    @value = address.to_s
    @ttl = Time.now.to_i + ttl
  end
end

class BasicTTLCache
  def initialize
    @cache = {}
  end

  def write(key, value, ttl)
    @cache[key] = DNSCacheEntry.new(value, ttl)
  end

  def is_valid?(key)
    return false unless @cache.exists?key
    t = Time.now.to_i
    if @cache[key].ttl > t
      return true
    end
    @cache.delete(key)
    return false
  end

  def read(key, type)
    if is_valid?key
      return @cache[key].value
    end
    return nil
  end
end

class DNSCached < Resolv::DNS
  def initialize(cache = nil)
    @cache = cache || BasicTTLCache.new
    @dns = Resolv::DNS.open()
  end

  def get_resource(name, type)
    if type == 4
      source = Resolv::DNS::Resolve::IN::A
    elsif type == 6
      source = Resolv::DNS::Resolve::IN::AAAA
    else
      raise ArgumentError, 'Type must be 4 or 6'
    end
    cache_key = "#{name}_#{type}"
    res = @cache.read(cache_key)
    if (res.nil?)
      res = @dns.getresource(name, source)
      @cache.write(cache_key, res.address, res.ttl)
    end
    res.address.to_s
  end
end


module Puppet::Parser::Functions
  dns = DNSCached.new
  newfunction(:ipresolve, :type => :rvalue, :arity => 2) do |args|
    name = args[0]
    type = args[1]
    return dns.get_resource(name, type)
  end
end

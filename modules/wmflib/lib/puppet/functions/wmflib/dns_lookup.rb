# SPDX-License-Identifier: MIT
# imported from https://github.com/dalen/puppet-dnsquery/blob/master/lib/puppet/functions/dns_lookup.rb
# Do a DNS lookup and returns an array of addresses.
# This will follow CNAMEs and return any matching IPv4 or IPv6 addresses.
# See the more specific functions if you only want one type returned.
#
# An optional lambda can be given to return a default value in case the
# lookup fails. The lambda will only be called if the lookup failed.
Puppet::Functions.create_function(:"wmflib::dns_lookup") do
  dispatch :dns_lookup do
    param 'String', :record
  end

  dispatch :dns_lookup_with_default do
    param 'String', :record
    block_param
  end

  def dns_lookup(record)
    Resolv::DNS.new.getaddresses(record).collect(&:to_s)
  end

  def dns_lookup_with_default(record)
    ret = dns_lookup(record)
    if ret.empty?
      yield
    else
      ret
    end
  rescue Resolv::ResolvError
    yield
  end
end

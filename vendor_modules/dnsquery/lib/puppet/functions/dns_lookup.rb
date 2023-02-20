# frozen_string_literal: true

# [DEPRECATED] Do a DNS lookup and returns an array of addresses.
# This will follow CNAMEs and return any matching IPv4 or IPv6 addresses.
# See the more specific functions if you only want one type returned.
Puppet::Functions.create_function(:dns_lookup) do
  # @deprecated Please use the namespaced version dnsquery::lookup
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of A and AAAA answers matching domain
  dispatch :dns_lookup do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Stdlib::IP::Address::Nosubnet]'
  end

  def dns_lookup(domain, &block)
    Puppet.deprecation_warning('dns_lookup', 'This method is deprecated please use the namespaced version dnsquery::lookup')
    call_function('dnsquery::lookup', domain, &block)
  end
end

# frozen_string_literal: true

# [DEPRECATED] Retrieves DNS AAAA records for a domain and them it as an array.
Puppet::Functions.create_function(:dns_aaaa) do
  # @deprecated Please use the namespaced version dnsquery::aaaa
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of AAAA records matching domain
  dispatch :dns_aaaa do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Stdlib::IP::Address::V6::Nosubnet]'
  end

  def dns_aaaa(domain, &block)
    Puppet.deprecation_warning('dns_aaaa', 'This method is deprecated please use the namespaced version dnsquery::aaaa')
    call_function('dnsquery::aaaa', domain, &block)
  end
end

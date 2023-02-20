# frozen_string_literal: true

# [DEPRECATED] Retrieves DNS A records for a domain and returns them as an array.
Puppet::Functions.create_function(:dns_a) do
  # @deprecated Please use the namespaced version dnsquery::a
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of A answers matching domain
  dispatch :dns_a do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Stdlib::IP::Address::V4::Nosubnet]'
  end

  def dns_a(domain, &block)
    Puppet.deprecation_warning('dns_a', 'This method is deprecated please use the namespaced version dnsquery::a')
    call_function('dnsquery::a', domain, &block)
  end
end

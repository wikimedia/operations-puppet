# frozen_string_literal: true

# [DEPRECATED] Retrieves DNS PTR records for a domain and returns them as an array.
Puppet::Functions.create_function(:dns_ptr) do
  # @deprecated Please use the namespaced version dnsquery::ptr
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of PTR answeres matching domain
  dispatch :dns_ptr do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Stdlib::Fqdn]'
  end

  def dns_ptr(domain, &block)
    Puppet.deprecation_warning('dns_ptr', 'This method is deprecated please use the namespaced version dnsquery::ptr')
    call_function('dnsquery::ptr', domain, &block)
  end
end

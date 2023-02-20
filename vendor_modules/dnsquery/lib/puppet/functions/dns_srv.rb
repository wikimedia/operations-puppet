# frozen_string_literal: true

# [DEPRECATED] Retirve the SRV domain for a specific domain
Puppet::Functions.create_function(:dns_srv) do
  # @deprecated Please use the namespaced version dnsquery::ptr
  # @param domain the dns question to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return The srv records for domain as an array of hashs
  dispatch :dns_srv do
    param 'String', :domain
    optional_block_param :block
    return_type 'Array[Dnsquery::Srv]'
  end

  def dns_srv(domain, &block)
    Puppet.deprecation_warning('dns_srv', 'This method is deprecated please use the namespaced version dnsquery::srv')
    call_function('dnsquery::srv', domain, &block)
  end
end

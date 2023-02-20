# frozen_string_literal: true

# Retirve the SRV domain for a specific domain
Puppet::Functions.create_function(:'dnsquery::srv') do
  # @param domain the dns question to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return The srv records for domain as an array of hashs
  dispatch :dns_srv do
    # TODO: resurrect https://github.com/puppetlabs/puppetlabs-stdlib/pull/1230
    param 'String', :domain
    optional_block_param :block
    return_type 'Array[Dnsquery::Srv]'
  end

  def dns_srv(domain)
    ret = Resolv::DNS.new.getresources(
      domain, Resolv::DNS::Resource::IN::SRV
    ).map do |res|
      {
        'priority' => res.priority,
        'weight' => res.weight,
        'port' => res.port,
        'target' => res.target.to_s
      }
    end
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end

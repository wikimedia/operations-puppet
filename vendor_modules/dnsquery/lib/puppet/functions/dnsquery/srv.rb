# frozen_string_literal: true

require_relative '../../../puppet_x/voxpupuli/dnsquery/util'

# Retirve the SRV domain for a specific domain
Puppet::Functions.create_function(:'dnsquery::srv') do
  # @param domain the dns question to lookup
  # @param config_info used to override the config for Resolve::DNS.new
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return The srv records for domain as an array of hashs
  dispatch :dns_srv do
    # TODO: resurrect https://github.com/puppetlabs/puppetlabs-stdlib/pull/1230
    param 'String', :domain
    optional_param 'Dnsquery::Config_info', :config_info
    optional_block_param :block
    return_type 'Array[Dnsquery::Srv]'
  end

  def dns_srv(domain, config_info = nil)
    resolver = PuppetX::Voxpupuli::Dnsquery::Utils.resolver(config_info)
    ret = resolver.getresources(
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

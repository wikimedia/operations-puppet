# frozen_string_literal: true

require_relative '../../../puppet_x/voxpupuli/dnsquery/util'

# Retrieves DNS MX records for a domain and returns them as an array.
Puppet::Functions.create_function(:'dnsquery::mx') do
  # @param domain the dns domain to lookup
  # @param config_info used to override the config for Resolve::DNS.new
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of hashes representing the mx records for domain
  dispatch :dns_mx do
    param 'Stdlib::Fqdn', :domain
    optional_param 'Optional[Dnsquery::Config_info]', :config_info
    optional_block_param :block
    return_type 'Array[Dnsquery::Mx]'
  end

  def dns_mx(domain, config_info = nil)
    resolver = PuppetX::Voxpupuli::Dnsquery::Utils.resolver(config_info)
    ret = resolver.getresources(
      domain, Resolv::DNS::Resource::IN::MX
    ).map do |res|
      {
        'preference' => res.preference,
        'exchange' => res.exchange.to_s
      }
    end
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end

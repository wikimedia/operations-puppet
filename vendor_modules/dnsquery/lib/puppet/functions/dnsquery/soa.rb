# frozen_string_literal: true

require_relative '../../../puppet_x/voxpupuli/dnsquery/util'

# Retrieves DNS SOA records and returns it as a hash.
Puppet::Functions.create_function(:'dnsquery::soa') do
  # @param question the dns question to lookup
  # @param config_info used to override the config for Resolve::DNS.new
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return The SOA record matching domain
  dispatch :dns_soa do
    param 'Stdlib::Fqdn', :question
    optional_param 'Dnsquery::Config_info', :config_info
    optional_block_param :block
    return_type 'Dnsquery::Soa'
  end

  def dns_soa(question, config_info = nil)
    resolver = PuppetX::Voxpupuli::Dnsquery::Utils.resolver(config_info)
    res = resolver.getresource(
      question, Resolv::DNS::Resource::IN::SOA
    )
    {
      'expire'  => res.expire,
      'minimum' => res.minimum,
      'mname'   => res.mname.to_s,
      'refresh' => res.refresh,
      'retry'   => res.retry,
      'rname'   => res.rname.to_s,
      'serial'  => res.serial,
    }
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end

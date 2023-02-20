# frozen_string_literal: true

# Retrieves DNS SOA records and returns it as a hash.
Puppet::Functions.create_function(:'dnsquery::soa') do
  # @param question the dns question to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return The SOA record matching domain
  dispatch :dns_soa do
    param 'Stdlib::Fqdn', :question
    optional_block_param :block
    return_type 'Dnsquery::Soa'
  end

  def dns_soa(question)
    res = Resolv::DNS.new.getresource(
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

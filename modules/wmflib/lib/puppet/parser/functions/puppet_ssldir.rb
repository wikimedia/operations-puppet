module Pupppet::Parser::Function
  newfunction(:puppet_ssldir, :type => :rvalue, :arity => 1) do |args|
    puppetmaster = args[0]

    if puppetmaster
      if lookup('fqdn') == puppetmaster or puppetmaster == 'localhost'
        return '/var/lib/puppet/server/ssl'
      else
        return '/var/lib/puppet/client/ssl'
      end
    else
      return '/var/lib/puppet/ssl'
    end
  end
end

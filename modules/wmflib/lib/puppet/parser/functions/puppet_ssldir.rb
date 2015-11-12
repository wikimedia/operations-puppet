# == Function puppet_ssldir( )
#
# Returns puppet's configured ssldir, based on the name of the puppetmaster
# variable provided, which can typically be obtained
module Puppet::Parser::Functions
  newfunction(:puppet_ssldir, :type => :rvalue) do |args|
    # If we're in production, or we're not on a self-hosted
    # puppetmaster, we can return the default value
    default =  '/var/lib/puppet/ssl'
    return default if lookupvar('::realm') != 'labs'
    begin
      puppetmaster = function_hiera(['role::puppet::self::master',
                                     lookupvar('::puppetmaster')])
      case puppetmaster
      when lookupvar('fqdn'), 'localhost'
      # Self-hosted puppetmaster client
        '/var/lib/puppet/server/ssl'
      else
        '/var/lib/puppet/client/ssl'
      end
    rescue Puppet::ParserError
      # Return the default if neither hiera nor the topscope variable are defined..
      # WARNING: this won't work specifically on the self-hosted puppetmasters
      # that have not specified either $::puppetmaster OR the hiera variable.
      # This should be rare enough that we can fix this afterwards
      default
    end
  end
end

# == Function puppet_ssldir( string $override = nil )
#
# Returns puppet's configured ssldir, using some heuristics.
# This function is needed because we have a separate configurations
# for the self-hosted puppetmasters ssl directory compared to the
# standard setup. If we're ever able to simplify or remove such
# differences, this function might become way simpler, or even
# disappear.
#
# It's possible to override the heuristics and provide an override
# parameter, which if set to 'master' will assume you are on a
# self-hosted puppetmaster.
#
# == Examples
#
# # returns the default result based on the catalog
# $ssldir = puppet_ssldir()
# # Forces ssldir to be the one of a self-hosted puppetmaster
# $ssldir = puppet_ssldir('master')
#
module Puppet::Parser::Functions
  newfunction(:puppet_ssldir, :type => :rvalue) do |overrides|
    # Check arguments
    override = overrides[0]

    fail("Only 'master', 'client' and undef " \
         "are valid arguments of puppet_ssldir") unless
        ['master', 'client', nil].include?override

    default =  '/var/lib/puppet/ssl'
    self_master = '/var/lib/puppet/server/ssl'
    self_client = '/var/lib/puppet/client/ssl'

    # Production uses the standard layout
    return default if lookupvar('::realm') != 'labs'

    # Self-hosted puppetmasters explicit setup
    case override
    when 'master'
      return self_master
    when 'client'
      return self_client
    end

    # Since all self-hosted puppetmasters are in .eqiad.wmflabs, while
    # the labs masters don't
    return default if lookupvar('::settings::certname') =~ /\.wikimedia\.org$/
    # Non-self-hosted puppetmasters all use the default ssldir
    puppetmaster = lookupvar('puppetmaster')
    puppetmaster ||= function_hiera(['role::puppet::self::master', ''])
    if puppetmaster == ''
      # Means we aren't using any of role::puppet::self!1!
      default
    elsif [lookupvar('hostname'), 'localhost', '', nil].include?puppetmaster
      self_master
    else
      self_client
    end
  end
end

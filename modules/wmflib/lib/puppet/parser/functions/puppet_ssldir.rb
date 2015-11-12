# == Function puppet_ssldir( string $override = nil )
#
# Returns puppet's configured ssldir, using some heuristics.
# It's possible to override the heuristics and provide an override
# parameter, which if set to 'master' will assume you are on a
# self-hosted puppetmaster.
#
# == Examples
#
# # returns the default result based on the catalog
# $ssldir = puppet_ssldir()
# # Forces ssldir to be the one of a
# $ssldir = puppet_ssldir('master') # will return the config for a
# self-hosted puppetmaster
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

    # Non-self-hosted puppetmasters all use the default ssldir
    return default if lookupvar('::settings::ssldir') == default &&
                      override.nil?

    # Self-hosted puppetmasters
    puppetmaster = function_hiera(['role::puppet::self::master',
                                   lookupvar('puppetmaster')])
    if [lookupvar('fqdn'), 'localhost', ''].include?puppetmaster ||
       override == 'master'
      self_master
    else
      self_client
    end
  end
end

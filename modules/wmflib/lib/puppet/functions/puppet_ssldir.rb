# SPDX-License-Identifier: Apache-2.0
# @summary
#   Returns puppet's configured ssldir, using some heuristics.
#
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
# @example Usage
#
#     # returns the default result based on the catalog
#     $ssldir = puppet_ssldir()
#     # Forces ssldir to be the one of a self-hosted puppetmaster
#     $ssldir = puppet_ssldir('master')
#
Puppet::Functions.create_function(:puppet_ssldir) do
  # @optional_param override
  #   One of 'master' or 'client' to override for self-hosted masters
  #
  dispatch :puppet_ssldir do
    optional_param "String[1]", :override
    return_type "String[1]"
  end
  def puppet_ssldir(override = nil)
    unless ["master", "client", nil].include? override
      fail("puppet_ssldir(): only 'master', 'client' and undef are valid")
    end

    default = "/var/lib/puppet/ssl"
    self_master = "/var/lib/puppet/server/ssl"
    self_client = "/var/lib/puppet/client/ssl"

    # Production uses the standard layout
    return default if closure_scope["::realm"] != "labs"

    # Self-hosted puppetmasters explicit setup
    case override
    when "master"
      return self_master
    when "client"
      return self_client
    end

    # Since all self-hosted puppetmasters are in .eqiad.wmflabs, while
    # the labs masters don't
    if closure_scope["::settings::certname"] =~ /\.wikimedia\.org$/
      return default
    end

    puppetmaster = closure_scope["puppetmaster"]
    if puppetmaster == "" || puppetmaster.nil?
      default
    elsif [
          closure_scope["facts"]["networking"]["hostname"],
          "localhost",
          "",
          nil
        ].include? puppetmaster
      self_master
    else
      self_client
    end
  end
end

# == Function: cache_app_route ($app)
#
# Given an app name from the list in hiera('cache::foo::apps'), this function
# will make the applayer routing choice and return the correct backend host(s)
# to use in VCL configuration.
#
# This code supports an app's 'route' hierdata being either an explicit dcname
# for which the app defines backend(s), or the magic value 'split'.
#
# For 'split', the code walks the cache::route_table from the current site
# downwards until it finds a site that's 'direct', and then uses that site as
# the applayer route.  This implies the constraint that if an app route is set
# to 'split', it must have backends defined for every dcname which maps to
# 'direct' in cache::route_table.
#
# Internally, this function references:
# $::site
# hiera('cluster')
# hiera('cache::foo::apps') # where foo is derived from cluster above
# hiera('cache::route_table')
#

# I wouldn't normally be so verbose with 'raise X unless Y', but it's hard to
# decipher what's going on when puppet fails in here otherwise

module Puppet::Parser::Functions
  newfunction(:cache_app_route, :type => :rvalue, :arity => 1) do |args|
    appname = args.first
    raise 'cache_app_route(): argument must be a String'
        unless appname.is_a? String

    err_pfx = "cache_app_route(#{appname}): "

    site = compiler.topscope.lookupvar('site')
    raise "#{err_pfx}missing $::site" unless site

    cache_rt = function_hiera(['cache::route_table'])
    raise "#{err_pfx}missing cache::route_table" unless cache_rt

    full_cluster = function_hiera(['cluster'])
    raise "#{err_pfx}missing cache cluster name" unless full_cluster

    cluster = full_cluster.gsub(/^cache_/, '')
    apps = function_hiera(["cache::#{cluster}::apps"])
    raise "#{err_pfx}missing cache::#{cluster}::apps" unless apps

    app = apps[appname]
    raise "#{err_pfx}missing cache::#{cluster}::apps::#{appname}" unless app

    route = app['route']
    raise "#{err_pfx}missing route attribute" unless route

    backends = app['backends']
    raise "#{err_pfx}missing backends attribute" unless backends

    if route == 'split'
      cache_rt.size.times do
        if cache_rt[site] == 'direct'
          raise "#{err_pfx}split: no backend for #{site}" unless backends[site]
          return backends[site]
        end
        site = cache_rt[site]
      end
      raise "#{err_pfx}infinite loop in cache::route_table"
    else
      raise "#{err_pfx}split: no backend for #{route}" unless backends[route]
      return backends[route]
    end
  end
end

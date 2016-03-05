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

module Puppet::Parser::Functions
  newfunction(:cache_app_route, :type => :rvalue, :arity => 1) do |args|
    app = args.first
    raise 'cache_app_route(): argument must be a string' unless app.is_a? String

    full_cluster = function_hiera(['cluster'])
    raise 'cache_app_route(): cannot find cache cluster name' unless full_cluster.is_a? String && full_cluster ~ /^cache_/
    cluster = full_cluster.gsub(/^cache_/, '')

    apps = function_hiera(["cache::#{cluster}::apps"])
    raise "Cannot find hiera(cache::#{cluster}::apps)" unless apps

    route = apps[app]['route']
    raise "Cannot find #{cluster}/#{app} route" unless route

    if route == 'split'
      site = compiler.topscope.lookupvar('site')
      raise "Cannot determine site" unless site
      cache_rt = function_hiera(['cache::route_table'])
      raise 'Cannot find hiera(cache::route_table)' unless cache_rt

      cache_rt.size.times do
        if cache_rt[site] == 'direct'
          return apps[app][site]
        end
        site = cache_rt[site]
      end
      raise "Infinite loop in cache::route_table for cluster #{cluster}"
    else
      return apps[app][route]
    end
  end
end

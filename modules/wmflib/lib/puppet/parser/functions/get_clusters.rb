# == Function: get_clusters
#
# Given a selector hash, which can contain a cluster selector and/or
# a site selector, this function will return a data
# structure that contains all nodes clustered by cluster/site.
#
# === Parameters
# [*selector*] An hash used to select the cluster and/or sites, if present;
#              allowed keys are 'site' and 'cluster', and should both be lists
#              of clusters and sites to select.
#
# === Examples
#
# # Return all nodes known to puppetDB
# $nodes = get_clusters()
#
# # All eqiad nodes grouped by cluster/site
# $eqiad_nodes = get_clusters({'site' => ['eqiad']})
#
# # All MediaWiki appserver and api nodes
# $mw_servers = get_clusters({'cluster' => ['appserver', 'appserver_api'})
#
module Puppet::Parser::Functions
  newfunction(:get_clusters, :type => :rvalue) do |args|
    all = {}
    # Ganglia config is the source of truth about clusters/site
    cluster_config = function_hiera(['ganglia_clusters', {}])

    # Arguments are an hash of selectors
    selector ||= {}
    selector = args[0] unless args.empty?
    if selector.include? 'cluster'
      clusters = selector['cluster']
    else
      clusters = cluster_config.keys
    end

    if selector.include? 'site'
      sites = selector['site']
    else
      sites = false
    end

    function_query_resources([false, '@@Ganglia::Cluster', false]).each do |node|
      cluster = node['parameters']['cluster']
      site = node['parameters']['site']
      fqdn = node['title']
      next unless clusters.include?cluster
      next if sites && !sites.include?(site)
      all[cluster] ||= {}
      all[cluster][site] ||= []
      all[cluster][site] << fqdn
    end
    all
  end
end

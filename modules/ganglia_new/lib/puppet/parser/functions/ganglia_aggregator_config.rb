#
# ganglia_aggregator_config - generates the aggregator config
#
def calc_url(aggregator, ip_octet)
  url, port = aggregator.split(':')
  port = port.to_i + ip_octet.to_i
  return sprintf("%s:%d", url, port)
end


module Puppet::Parser::Functions
  newfunction(:ganglia_aggregator_config, :type => :rvalue) do |args|
    config = {}
    site_wide_aggregators = {}
    clusters = function_hiera(['ganglia_clusters'])
    clusters.each do |cluster, data|
      data['sites'].each do |site, aggregators|
        name = sprintf("%s %s", data['name'], site)
        # We are moving away from the traditional cluster-dedicated aggregators
        # To switch one cluster from ganglia to ganglia_new it will be enough to
        # remove its aggregators list, and to re-define the ganglia_class hiera variable
        if not aggregators.empty?
          aggregator = aggregators.join(' ')
        else
          unless site_wide_aggregators.include? site
            site_wide_aggregators[site] = function_hiera(['ganglia_aggregators', nil, site])
          end
          # Compute the port to use
          aggregator = calc_url(site_wide_aggregators[site], data['id'])
        end
        config[name] = aggregator
      end
    end
    return config
  end
end

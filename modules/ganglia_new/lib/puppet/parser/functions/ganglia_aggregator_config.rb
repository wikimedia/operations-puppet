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
    site_config = {}
    site_wide_aggregators = {}
    clusters = function_hiera(['ganglia_clusters'])
    clusters.each do |cluster, data|
      data['sites'].each do |site, aggregators|
        name = sprintf("%s %s", data['name'], site)
        unless site_config.include? site
          site_config[site] = function_hiera(['ganglia_class', nil, site])
        end
        if site_config[site] == 'old'
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

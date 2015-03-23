#
# ganglia_aggregator_config - generates the aggregator config
#
def calc_url(aggregator, ip_octect)
  url, port = aggregator.split(':')
  port = port.to_i + ip_octect.to_i
  return sprintf("%s:%d", url, port)
end


module Puppet::Parser::Functions
  newfunction(:ganglia_aggregator_config, :type => :rvalue) do |args|
    config = {}
    site_config = {}
    clusters = function_hiera(['ganglia_clusters'])
    clusters.each do |cluster, data|
      data['sites'].each do |site, aggregators|
        name = sprintf("%s %s", data['name'], site)
        unless site_config.include? site
          site_config[site] = function_hiera(['ganglia_class'], nil, [site])
        end
        if site_config[site] == 'old'
          aggregator = aggregators.join(' ')
        else
          # Compute the port to use
          aggregator = calc_url(aggregators, data['ip_oct'])
        end
        config[name] = aggregator
      end
    end
    return config
  end
end

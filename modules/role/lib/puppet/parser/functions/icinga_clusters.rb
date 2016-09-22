# === Function icinga_clusters
#
# Simple function to map the cluster data structure to what expected by
# monitoring::group.
#
module Puppet::Parser::Functions
  newfunction(:icinga_clusters, :type => :rvalue) do |_|
    icinga ||= {}
    clusters = function_hiera(['ganglia_clusters'])
    clusters.each do |cluster, data|
      data['sites'].keys.each do |site|
        icinga["#{cluster}_#{site}"] = {
          'description' => "#{data['description']} #{site}"
        }
      end
    end
    icinga
  end
end

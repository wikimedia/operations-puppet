# SPDX-License-Identifier: Apache-2.0
Puppet::Functions.create_function(:'wmflib::get_clusters') do
  dispatch :get_clusters do
    optional_param 'Wmflib::Selector', :selector
  end

  def get_clusters(selector = {})
    clusters = selector.fetch('cluster', call_function('lookup', 'wikimedia_clusters').keys)
    sites = selector.fetch('site', [])
    pql = <<~PQL
    resources[certname, parameters] {
        type = "Class" and title = "Cumin::Selector"
        order by parameters
    }
    PQL
    call_function('wmflib::puppetdb_query', pql).select do |res|
      clusters.include?(res['parameters']['cluster']) &&
        (sites.empty? || sites.include?(res['parameters']['site']))
    end.reduce({}) do |memo, res|  # rubocop:disable Style/MultilineBlockChain
      cluster = res['parameters']['cluster']
      site = res['parameters']['site']
      memo[cluster] ||= {}
      memo[cluster][site] ||= []
      memo[cluster][site] << res['certname']
      memo
    end
  end
end

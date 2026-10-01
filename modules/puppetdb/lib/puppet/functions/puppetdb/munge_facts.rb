# SPDX-License-Identifier: Apache-2.0
Puppet::Functions.create_function(:"puppetdb::munge_facts") do
  dispatch :munge_facts do
    param "Array[Hash]", :hosts
  end

  def munge_facts(hosts)
    facts_out = Hash.new { |h, k| h[k] = {} }
    hosts.each do |host|
      host.each do |k, v|
        facts_out[host["certname"]][k] = v if k =~ /^facts/ && v
      end
    end
    facts_out
  end
end

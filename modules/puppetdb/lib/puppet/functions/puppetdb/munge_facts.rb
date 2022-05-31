# SPDX-License-Identifier: Apache-2.0
Puppet::Functions.create_function(:'puppetdb::munge_facts') do
  dispatch :munge_facts do
    param 'Array[Hash]', :facts
  end

  def munge_facts(facts)
    facts_out = Hash.new {|h, k| h[k] = {}}
    facts.each do |f|
      facts_out[f['certname']][f['name']] = f['value']
    end
    facts_out
  end
end

# SPDX-License-Identifier: Apache-2.0
# Return all Pontoon stack hosts

require_relative '../../../puppet_x/pontoon/helper.rb'

Puppet::Functions.create_function(:'pontoon::hosts') do
  dispatch :hosts do
    return_type 'Array[Stdlib::Fqdn]'
  end

  def hosts
    rolemap = PuppetX::Pontoon::Helper.load_rolemap
    rolemap.values.flatten.compact.uniq
  end
end

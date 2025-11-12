# SPDX-License-Identifier: Apache-2.0
# Return hosts for a given role, reading from Pontoon's rolemap file.

require_relative '../../../puppet_x/pontoon/helper.rb'

Puppet::Functions.create_function(:'pontoon::hosts_for_role') do
  dispatch :hosts_for_role do
    param 'String', :role
    return_type 'Optional[Array[Stdlib::Fqdn]]'
  end

  def hosts_for_role(role)
    rolemap = PuppetX::Pontoon::Helper.load_rolemap
    rolemap[role]
  end
end

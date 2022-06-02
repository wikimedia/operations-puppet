# SPDX-License-Identifier: Apache-2.0
# Return hosts for a given role, reading from Pontoon's rolemap file.
Puppet::Functions.create_function(:'pontoon::hosts_for_role') do
  dispatch :hosts_for_role do
    param 'String', :role
    return_type 'Optional[Array[Stdlib::Fqdn]]'
  end

  def hosts_for_role(role)
    # Accessing the enviroment from puppet functions doesn't seem to be a thing, hence this function
    # is ruby
    stack_file = ENV['PONTOON_STACK_FILE'] || '/etc/pontoon-stack'
    stack_path = ENV['PONTOON_STACK_PATH'] || '/var/lib/git/operations/puppet/modules/pontoon/files'

    fail("Pontoon stack file #{stack_file} not found") unless File.exist?(stack_file)

    pontoon_stack = File.read(stack_file).chop
    rolemap_path = File.join(stack_path, pontoon_stack, 'rolemap.yaml')

    fail("Rolemap #{rolemap_path} not found") unless File.exist?(rolemap_path)

    rolemap = YAML.load_file(rolemap_path)

    rolemap[role]
  end
end

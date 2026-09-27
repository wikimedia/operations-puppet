# frozen_string_literal: true

Facter.add(:volume_groups) do
  # Fact should be confined to only linux servers that have the lvs command
  confine do
    Facter.value('kernel') == 'Linux' &&
      Facter::Core::Execution.which('vgs')
  end

  setcode do
    # Require the helper methods to reduce duplication
    require 'puppet_x/lvm/output'

    # List columns here that can be passed to the lvs -o command. Dont't
    # include things in here that might be bland as we currently can't deal
    # with them
    columns = [
      'vg_uuid',
      'vg_name',
      'vg_attr',
      'vg_permissions',
      'vg_allocation_policy',
      'vg_size',
      'vg_free',
    ]

    output = Facter::Core::Execution.exec("vgs -o #{columns.join(',')}  --noheading --nosuffix")
    Puppet_X::LVM::Output.parse('vg_name', columns, output)
  end
end

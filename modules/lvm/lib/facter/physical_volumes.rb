Facter.add(:physical_volumes) do
  # Fact should be confined to only linux servers that have the lvs command
  confine do
    Facter.value('kernel') == 'Linux' &&
      Facter::Core::Execution.which('pvs')
  end

  setcode do
    # Require the helper methods to reduce duplication
    require 'puppet_x/lvm/output'

    # List columns here that can be passed to the lvs -o command. Dont't
    # include things in here that might be bland as we currently can't deal
    # with them
    columns = [
      'pv_uuid',
      'dev_size',
      'pv_name',
      'pe_start',
      'pv_size',
      'pv_free',
      'pv_used',
      'pv_attr',
      'pv_pe_count',
      'pv_pe_alloc_count',
      'pv_mda_count',
      'pv_mda_used_count',
      'pv_ba_start',
      'pv_ba_size',
    ]

    output = Facter::Core::Execution.exec("pvs -o #{columns.join(',')}  --noheading --nosuffix")
    Puppet_X::LVM::Output.parse('pv_name', columns, output)
  end
end

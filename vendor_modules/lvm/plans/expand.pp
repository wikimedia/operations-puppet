# @summary An opinionated method for expanding storage on machines that use LVM.
#   If this doesn't fit your needs, simply tie the tasks together in
#   some way that does.
#
# @param server The target for the plan
# @param volume_group The volume group to which the logical volume belongs
# @param logical_volume The logical volume which is to be expanded
# @param additional_size How much size to add to the LV. This should be
#   specified in LVM format i.e. "200m" or "2.5g"
# @param disks Any physical disks that should be added to the volume group as
#   part of the expand process
# @param resize_fs Wheather or not to resize the filesystem
plan lvm::expand (
  String        $server,
  String        $volume_group,
  String        $logical_volume,
  String        $additional_size,
  Array[String] $disks = [],
  Boolean       $resize_fs = true,
) {
  $targets = get_targets($server)

  # Fail if we are trying to run on many servers
  if $targets.length > 1 {
    fail('This plan should only be run against one server at a time')
  }

  # The target should be the first server
  $target = $targets[0]

  # Refresh facts for this server. Ideally we would call directly to the
  # `facts` plan. But there seems to be a bug preventing this.
  $result_set = run_task('facts::ruby', $target, '_catch_errors' => true)

  $result_set.each |$result| {
    # Store facts for nodes from which they were succefully retrieved
    if ($result.ok) {
      add_facts($result.target, $result.value)
    }
  }

  unless $disks.empty {
    # If we have passed disks then we want to create a PV for each of these
    # disks, then add them to the LV
    $disks.each |$disk| {
      # Ensure that the PV exists
      run_task('lvm::ensure_pv', $target, {
          'ensure' => 'present',
          'name'   => $disk,
      })
    }

    # Extend the volume group to also contain the new disks
    run_task('lvm::extend_vg', $target, {
        'volume_group'     => $volume_group,
        'physical_volumes' => $disks,
    })
  }

  # Now we need to extend the logical volume
  # Get the current size in bytes
  $current_size_bytes    = lvm::size_to_bytes($target.facts['logical_volumes'][$logical_volume]['size'])
  # Get the additonal size in bytes
  $additional_size_bytes = lvm::size_to_bytes($additional_size)
  # Add them together
  $new_size_bytes        = $current_size_bytes + $additional_size_bytes
  # Convert back to a fromat that LVM wants i.e. "150g"
  $new_size              = lvm::bytes_to_size($new_size_bytes)

  $expand_result = run_task('lvm::ensure_lv', $target, {
      'ensure'       => 'present',
      'name'         => $logical_volume,
      'volume_group' => $volume_group,
      'size'         => $new_size,
      'resize_fs'    => true,
  })

  return $expand_result.first.message
}

# Create LV needed by swift and instruct udev to symlink it to its expected
# location to simulate a disk partition.
class profile::swift::storage::labs {
  include ::lvm

  lvm::logical_volume { 'lv-a1':
    volume_group => 'vd',
    createfs     => false,
    mounted      => false,
    extents      => '80%FREE',
  }

  udev::rule { 'swift_storage_labs':
    content  => "ENV{DM_LV_NAME}==\"lv-a1\", ENV{DM_VG_NAME}==\"vd\", SYMLINK+=\"swift/lv-a1\"\n",
    priority => 57,
    require  => Lvm::Logical_volume['lv-a1'],
  }
}

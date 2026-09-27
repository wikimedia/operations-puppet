# @summary Manage a logical volume.
#
# @param volume_group The volume group name associated with this logical volume.
# This will automatically set this volume group as a dependency,
# but it must be defined elsewhere using the volume_group resource type.
#
# @param size  Configures the size of the filesystem. Supports filesystem resizing. The size will be rounded up to the nearest multiple of
# the partition size.
#
# @param initial_size The initial size of the logical volume. This will only apply to newly-created volumes
#
# @param ensure
#
# @param options Params for the mkfs command
#
# @param pass
#
# @param dump
#
# @param fs_type The file system type. eg. ext3.
#
# @param mkfs_options
#
# @param mountpath
#
# @param mountpath_require
#
# @param mounted If puppet should mount the volume. This only affects what puppet will do, and not what will be mounted at boot-time.
#
# @param createfs
#
# @param extents The number of logical extents to allocate for the new logical volume. Set to undef to use all available space
#
# @param stripes The number of stripes to allocate for the new logical volume.
#
# @param stripesize  The stripesize to use for the new logical volume.
#
# @param readahead The readahead count to use for the new logical volume.
#
# @param range - Set to true if the ‘size’ parameter specified, is just the minimum size you need
# (if the LV found is larger then the size requests this is just logged not causing a FAIL)
#
# @param size_is_minsize Lists strings for access control for connection method, users, databases, IPv4 addresses;
#
# @param type Configures the logical volume type. AIX only
#
# @param thinpool - Set to true to create a thin pool or to pool name to create thin volume
#
# @param poolmetadatasize Set the initial size of the logical volume pool metadata on creation
#
# @param mirror The number of mirrors of the volume.
#
# @param mirrorlog How to store the mirror log (Allowed values: core, disk, mirrored).
#
# @param no_sync An optimization in lvcreate, at least on Linux.
#
# @param region_size A mirror is divided into regions of this size (in MB), the mirror log uses this granularity to track which regions
# are in sync. Cannot be changed on already mirrored volume.
# Take your mirror size in terabytes and round up that number to the next power of 2, using that number as the -R argument
#
# @param alloc The allocation policy when a command needs to allocate Physical Extents from the Volume Group.
#
# @param yes_flag If set to true, do not prompt for confirmation interactively but always assume the answer yes.
#
define lvm::logical_volume (
  String[1] $volume_group,
  Optional[String[1]] $size                                                     = undef,
  Optional[String[1]] $initial_size                                             = undef,
  Enum['absent', 'present'] $ensure                                             = present,
  String[1] $options                                                            = 'defaults',
  Variant[String[1], Integer] $pass                                             = '2',
  Variant[String[1], Integer] $dump                                             = '0',
  String[1] $fs_type                                                            = 'ext4',
  Optional[String[1]] $mkfs_options                                             = undef,
  Stdlib::Absolutepath $mountpath                                               = "/${name}",
  Boolean $mountpath_require                                                    = false,
  Boolean $mounted                                                              = true,
  Boolean $createfs                                                             = true,
  Optional[String[1]] $extents                                                  = undef,
  Optional[Variant[String[1], Integer]] $stripes                                = undef,
  Optional[Variant[String[1], Integer]] $stripesize                             = undef,
  Optional[Variant[String[1], Integer]] $readahead                              = undef,
  Optional[Enum['maximum', 'minimum']] $range                                   = undef,
  Optional[Boolean] $size_is_minsize                                            = undef,
  Optional[String[1]] $type                                                     = undef,
  Variant[Boolean, String] $thinpool                                            = false,
  Optional[Integer[0, 4]] $poolmetadatasize                                     = undef,
  Optional[String[1]] $mirror                                                   = undef,
  Optional[Enum['core', 'disk', 'mirrored']] $mirrorlog                         = undef,
  Optional[Boolean] $no_sync                                                    = undef,
  Optional[Variant[String[1], Integer]] $region_size                            = undef,
  Optional[Enum['anywhere', 'contiguous', 'cling', 'inherit', 'normal']] $alloc = undef,
  Boolean $yes_flag                                                             = false,
) {
  $lvm_device_path = "/dev/${volume_group}/${name}"

  if $mountpath_require and $fs_type != 'swap' {
    Mount {
      require => File[$mountpath],
    }
  }

  if $fs_type == 'swap' {
    $mount_title     = $lvm_device_path
    $fixed_mountpath = "swap_${lvm_device_path}"
    $fixed_pass      = 0
    $fixed_dump      = 0
    $mount_ensure    = $ensure ? {
      'absent' => absent,
      default  => present,
    }
  } else {
    $mount_title     = $mountpath
    $fixed_mountpath = $mountpath
    $fixed_pass      = $pass
    $fixed_dump      = $dump
    $mount_ensure    = $ensure ? {
      'absent' => absent,
      default  => $mounted ? {
        true      => mounted,
        false     => present,
      }
    }
  }

  if $ensure == 'present' and $createfs {
    Logical_volume[$name]
    -> Filesystem[$lvm_device_path]
    -> Mount[$mount_title]
  } elsif $ensure != 'present' and $createfs {
    Mount[$mount_title]
    -> Filesystem[$lvm_device_path]
    -> Logical_volume[$name]
  }

  logical_volume { $name:
    ensure           => $ensure,
    volume_group     => $volume_group,
    size             => $size,
    initial_size     => $initial_size,
    stripes          => $stripes,
    stripesize       => $stripesize,
    readahead        => $readahead,
    extents          => $extents,
    range            => $range,
    size_is_minsize  => $size_is_minsize,
    type             => $type,
    thinpool         => $thinpool,
    poolmetadatasize => $poolmetadatasize,
    mirror           => $mirror,
    mirrorlog        => $mirrorlog,
    no_sync          => $no_sync,
    region_size      => $region_size,
    alloc            => $alloc,
    yes_flag         => $yes_flag,
  }

  if $createfs {
    filesystem { $lvm_device_path:
      ensure  => $ensure,
      fs_type => $fs_type,
      options => $mkfs_options,
    }
  }

  if $createfs or $ensure != 'present' {
    if $fs_type != 'swap' {
      exec { "ensure mountpoint '${fixed_mountpath}' exists":
        path    => ['/bin', '/usr/bin', '/sbin'],
        command => "mkdir -p ${fixed_mountpath}",
        unless  => "test -d ${fixed_mountpath}",
        onlyif  => "lvs /dev/${volume_group}/${name} > /dev/null 2>&1",
        before  => Mount[$mount_title],
      }
    }

    mount { $mount_title:
      ensure  => $mount_ensure,
      name    => $fixed_mountpath,
      device  => $lvm_device_path,
      fstype  => $fs_type,
      options => $options,
      pass    => $fixed_pass,
      dump    => $fixed_dump,
      atboot  => true,
    }
  }
}

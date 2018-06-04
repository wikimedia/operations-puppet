# Puppet LVM Module

Provides Logical Resource Management (LVM) features for Puppet.

## Usage Examples

This module provides four resource types (and associated providers):
`volume_group`, `logical_volume`, `physical_volume`, and `filesystem`.

The basic dependency graph needed to define a working logical volume
looks something like:

    filesystem -> logical_volume -> volume_group -> physical_volume(s)

Here's a simple working example:

```puppet
physical_volume { '/dev/hdc':
  ensure => present,
}

volume_group { 'myvg':
  ensure           => present,
  physical_volumes => '/dev/hdc',
}

logical_volume { 'mylv':
  ensure       => present,
  volume_group => 'myvg',
  size         => '20G',
}

filesystem { '/dev/myvg/mylv':
  ensure  => present,
  fs_type => 'ext3',
  options => '-b 4096 -E stride=32,stripe-width=64',
}
```

This simple 1 physical volume, 1 volume group, 1 logical volume case
is provided as a simple `volume` definition, as well.  The above could
be shortened to be:

```puppet
lvm::volume { 'mylv':
  ensure => present,
  vg     => 'myvg',
  pv     => '/dev/hdc',
  fstype => 'ext3',
  size   => '20G',
}
```

You can also describe your Volume Group like this:

```puppet
class { 'lvm':
  volume_groups    => {
    'myvg' => {
      physical_volumes => [ '/dev/sda2', '/dev/sda3', ],
      logical_volumes  => {
        'opt'    => {'size' => '20G'},
        'tmp'    => {'size' => '1G' },
        'usr'    => {'size' => '3G' },
        'var'    => {'size' => '15G'},
        'home'   => {'size' => '5G' },
        'backup' => {
          'size'              => '5G',
          'mountpath'         => '/var/backups',
          'mountpath_require' => true,
        },
      },
    },
  },
}
```

This could be really convenient when used with hiera:

```puppet
include ::lvm
```
and
```yaml
---
lvm::volume_groups:
  myvg:
    physical_volumes:
      - /dev/sda2
      - /dev/sda3
    logical_volumes:
      opt:
        size: 20G
      tmp:
        size: 1G
      usr:
        size: 3G
      var:
        size: 15G
      home:
        size: 5G
      backup:
        size: 5G
        mountpath: /var/backups
        mountpath_require: true
```
or to just build the VG if it does not exist
```yaml
---
lvm::volume_groups:
  myvg:
    createonly: true
    physical_volumes:
      /dev/sda2:
        unless_vg: 'myvg'
      /dev/sda3:
        unless_vg: 'myvg'
    logical_volumes:
      opt:
        size: 20G
      tmp:
        size: 1G
      usr:
        size: 3G
      var:
        size: 15G
      home:
        size: 5G
      backup:
        size: 5G
        mountpath: /var/backups
        mountpath_require: true
```

Except that in the latter case you cannot specify create options.
If you want to omit the file system type, but still specify the size of the
logical volume, i.e. in the case if you are planning on using this logical
volume as a swap partition or a block device for a virtual machine image, you
need to use a hash to pass the parameters to the definition.

If you need a more complex configuration, you'll need to build the
resources out yourself.

## Optional Values
  The `unless_vg` (physical_volume) and `createonly` (volume_group) will check 
  to see if "myvg" exists.  If "myvg" does exist then they will not modify
  the physical volume or volume_group.  This is useful if your environment
  is built with certain disks but they change while the server grows, shrinks
  or moves.
 
  Example:
```puppet
    physical_volume { "/dev/hdc":
        ensure => present,
        unless_vg => "myvg"
    }
    volume_group { "myvg":
        ensure => present,
        physical_volumes => "/dev/hdc",
        createonly => true
    }
```

## Type Documentation

### filesystem

* name (Parameter) (Namevar)
* ensure (Property)
* fs_type (Parameter) - The file system type. eg. ext3.
* mkfs_cmd (Parameter) - Command to use to create the file system. Defaults to `mkswap` for `fs_type=swap`, otherwise `mkfs.{fs_type}`
* options (Parameter) - Params for the mkfs command. eg. `-l internal,agcount=x`

### logical_volume

* name (Parameter) (Namevar) - The name of the logical volume. This is the unqualified name and will be automatically added to the volume group’s device path (e.g., ‘/dev/$vg/$lv’).
* ensure (Property)
* alloc (Parameter) - Selects the allocation policy when a command needs to allocate Physical Extents from the Volume Group. Allowed Values:
    - `:anywhere`
    - `:contiguous`
    - `:cling`
    - `:inherit`
    - `:normal`
* extents (Parameter) - The number of logical extents to allocate for the new logical volume. Set to undef to use all available space
* initial_size (Parameter) - The initial size of the logical volume. This will only apply to newly-created volumes
* minor (Parameter) - Set the minor number
* mirror (Property) - The number of mirrors of the volume.
* mirrorlog (Property) - How to store the mirror log (core, disk, mirrored).  Allowed Values:
   -  `:core`
   -  `:disk`
   -  `:mirrored`
* mounted - If puppet should mount the volume. This only affects what puppet will do, and not what will be mounted at boot-time.
* no_sync (Parameter) - An optimization in lvcreate, at least on Linux.
* persistent (Parameter) - Set to true to make the block device persistent
* poolmetadatasize (Parameter) - Set the initial size of the logical volume pool metadata on creation
* readahead (Parameter) - The readahead count to use for the new logical volume.
* region_size (Parameter) - A mirror is divided into regions of this size (in MB), the mirror log uses this granularity to track which regions are in sync. CAN NOT BE CHANGED on already mirrored volume. Take your mirror size in terabytes and round up that number to the next power of 2, using that number as the -R argument.
* size (Property) - The size of the logical volume. Set to undef to use all available space
* size_is_minsize (Parameter) Default value: `false` - Set to true if the ‘size’ parameter specified, is just the minimum size you need (if the LV found is larger then the size requests this is just logged not causing a FAIL)
* stripes (Parameter) - The number of stripes to allocate for the new logical volume.
* stripesize (Parameter) - The stripesize to use for the new logical volume.
* thinpool (Parameter) - Default value: `false` - Set to true to create a thin pool
* volume_group (Parameter) - The volume group name associated with this logical volume. This will automatically set this volume group as a dependency, but it must be defined elsewhere using the volume_group resource type.

### physical_volume

* name (Parameter) (Namevar)
* ensure (Property) -
* force (Parameter) Default value: `false` - Force the creation without any confirmation. Allowed Values:
   - `true`
   - `false`
* unless_vg (Parameter) - Do not do anything if the VG already exists. The value should be the name of the volume group to check for.

### volume_group

* name (Parameter) (Namevar) - The name of the volume group.
* ensure (Property)
* createonly (Parameter) Default value: false - If set to true the volume group will be created if it does not exist. If the volume group does exist no action will be taken. Defaults to `false`.  Allowed Values:
   - `true`
   - `false`
* followsymlinks (Parameter) - If set to true all current and wanted values of the physical_volumes property will be followed to their real files on disk if they are in fact symlinks. This is useful to have Puppet determine what the actual PV device is if the property value is a symlink, like '/dev/disk/by-path/xxxx -> ../../sda'. Defaults to `false`.
* physical_volumes (Property) - The list of physical volumes to be included in the volume group; this will automatically set these as dependencies, but they must be defined elsewhere using the physical_volume resource type.

## AIX Specific Type Documentation


There are a number of AIX specific parameters and properties. The regular
parameters documented above also apply to AIX systems.


### filesystem

* accounting (Parameter) - Specify accounting subsystem support, Allowed Values:
    * `true`
    * `false`
* ag_size (Parameter) - Specify the allocation group size in megabytes, Allowed Values:
    * `/\d+/`
* agblksize (Parameter) - JFS2 block size in bytes, Allowed Values:
    * `/\d+/`
* atboot (Parameter) - Specify whether the file system is mounted at boot time, Allowed Values:
    * `true`
    * `false`
* compress (Parameter) - Data compression, LZ or no. Allowed Values:
    * `:LG`
    * `:no`
* device (Parameter) - Device to create the filesystem on, this can be a device or a logical volume.
* encrypted (Parameter) - Specify and encrypted filesystem. Allowed Values:
    * `true`
    * `false`
* extended_attributes (Parameter) - Format to be used to store extended attributes. Allowed Values:
    * `:v1`
    * `:v2`
* frag (Parameter) - JFS fragment size in bytes.  Allowed Values:
    * `/\d+/`
* initial_size (Parameter) - Initial size of the filesystem, Used only for resource creation, when using this option Puppet will not manage or maintain the size. To resize filesystems see the size property.
* isnapshot (Parameter) - Specify whether the filesystem supports internal snapshots, Allowed Values:
    * `true`
    * `false`
* large_files (Parameter) - Large file enabled file system. Allowed Values:
    * `true`
    * `false`
* log_partitions (Parameter) - Specify the size of the log logical volume as number of logical partitions,
* logname (Parameter) - Configure the log logical volume.
* logsize (Parameter) - Size for an inline log in MB, Allowed Values:
    * `/\d+/`
* maxext (Parameter) - Size of a file extent in file system blocks, Allowed Values:
    * `/\d+/`
* mount_options (Parameter) - Specify the options to be passed to the mount command.
* mountgroup (Parameter) - Mount group for the filesystem,
* mountguard (Parameter) - Enable the mountguard. Allowed Values:
    * `true`
    * `false`
* nbpi (Parameter) - Bytes per inode. Allowed Values:
    * `/\d+/`
* nodename (Parameter) - Specify the remote host where the filesystem resides.
* perms (Parameter) - Permissions for the filesystem, Allowed Values:
    * `:ro`
    * `:rw`
* size (Property) - Configures the size of the filesystem. Supports filesystem resizing. The size will be rounded up to the nearest multiple of the partition size.
* vix (Parameter) - Specify that the file system can allocate inode extents smaller than the default, Allowed Values:
    * `true`
    * `false`
* volume_group (Parameter) - Volume group that the file system should be greated on.

### logical_volume

* range (Parameter) - Sets the inter-physical volume allocation policy. AIX only
* type (Parameter) - Configures the logical volume type. AIX only


## Limitations

### Namespacing

Due to puppet's lack of composite keys for resources, you currently
cannot define two `logical_volume` resources with the same name but
a different `volume_group`.

### Removing Physical Volumes

You should not remove a `physical_volume` from a `volume_group`
without ensuring the physical volume is no longer in use by a logical
volume (and possibly doing a data migration with the `pvmove` executable).

Removing a `physical_volume` from a `volume_group` resource will cause the
`pvreduce` to be executed -- no attempt is made to ensure `pvreduce`
does not attempt to remove a physical volume in-use.

### Resizing Logical Volumes

Logical volume size can be extended, but not reduced -- this is for
safety, as manual intervention is probably required for data
migration, etc.


# Contributors

Bruce Williams <bruce@codefluency.com>

Daniel Kerwin <github@reductivelabs.com>

Luke Kanies <luke@reductivelabs.com>

Matthaus Litteken <matthaus@puppetlabs.com>

Michael Stahnke <stahnma@puppetlabs.com>

Mikael Fridh <frimik@gmail.com>

Tim Hawes <github@reductivelabs.com>

Yury V. Zaytsev <yury@shurup.com>

csschwe <csschwe@gmail.com>

windowsrefund <windowsrefund@gmail.com>

Adam Gibbins <github@adamgibbins.com>

Steffen Zieger <github@saz.sh>

Jason A. Smith <smithj4@bnl.gov>

Mathieu Bornoz <mathieu.bornoz@camptocamp.com>

Cédric Jeanneret <cedric.jeanneret@camptocamp.com>

Raphaël Pinson <raphael.pinson@camptocamp.com>

Garrett Honeycutt <code@garretthoneycutt.com>

[More Contributers](https://github.com/puppetlabs/puppetlabs-lvm/graphs/contributors)

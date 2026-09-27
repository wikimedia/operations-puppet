# Puppet LVM Module

Provides Logical Volume Manager (LVM) types and providers for Puppet.

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
include lvm
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
  ensure    => present,
  unless_vg => "myvg",
}

volume_group { "myvg":
  ensure           => present,
  physical_volumes => "/dev/hdc",
  createonly       => true,
}
```

## Tasks

See [tasks reference](REFERENCE.md#tasks)

## Plans

See [plans reference](REFERENCE.md#plans)

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

## Deprecation Notice

Some facts reported by this module are being deprecated in favor of upcoming structured facts.  The following facts are being deprecated:

* `lvm_vg_*`
* `lvm_vg_*_pvs`
* `lvm_pv_*`

## License

This codebase is licensed under the GPL 2.0, however due to the nature of the
codebase the open source dependencies may also use a combination of
[AGPL](https://opensource.org/license/agpl-v3/),
[BSD-2](https://opensource.org/license/bsd-2-clause/),
[BSD-3](https://opensource.org/license/bsd-3-clause/),
[GPL2.0](https://opensource.org/license/gpl-2-0/),
[LGPL](https://opensource.org/license/lgpl-3-0/),
[MIT](https://opensource.org/license/mit/) and
[MPL](https://opensource.org/license/mpl-2-0/).

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

[More Contributors](https://github.com/puppetlabs/puppetlabs-lvm/graphs/contributors)

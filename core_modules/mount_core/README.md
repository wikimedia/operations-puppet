
# mount_core

[![Modules Status](https://github.com/puppetlabs/puppetlabs-mount_core/workflows/%5BDaily%5D%20Unit%20Tests%20with%20nightly%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mount_core/actions)
[![Modules Status](https://github.com/puppetlabs/puppetlabs-mount_core/workflows/Static%20Code%20Analysis/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mount_core/actions) 
[![Modules Status](https://github.com/puppetlabs/puppetlabs-mount_core/workflows/Unit%20Tests%20with%20nightly%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mount_core/actions) 
[![Modules Status](https://github.com/puppetlabs/puppetlabs-mount_core/workflows/Unit%20Tests%20with%20released%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mount_core/actions)


#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with mount_core](#setup)
    * [What mount_core affects](#what-mount-affects)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hook peek at what the module is doing and how](#reference)
5. [Development - Guide for contributing to the module](#development)

<a id="description"></a>
## Description

The mount_core module manages mounted filesystems and mount tables. The module
has some limitations, and you may be better off using the [mount_providers
module](https://forge.puppet.com/puppetlabs/mount_providers), which can manage
mountpoints and mounttab resources independently.

<a id="setup"></a>
## Setup

<a id="what-mount-affects"></a>
### What mount_core affects

The module can mount and unmount filesystems, and manage mount tables such as
`/etc/fstab`, `/etc/vfstab`, or `/etc/filesystems` depending on your operating system.

Mount resources can respond to refresh events, and can remount a filesystem in
response to an event from another resource.

Mount resources automatically create relationships with directories that are
either ancestors of the mounted directory or children. This way Puppet will
automatically create ancestor directories before the mount point, and will do
that before managing directories and files within the mounted directory.

<a id="usage"></a>
## Usage

To mount the device `/dev/foo` at `/mnt/foo` as read-only, use the following code:

```
mount { '/mnt/foo':
  ensure  => 'mounted',
  device  => '/dev/foo',
  fstype  => 'ext3',
  options => 'ro',
}
```

<a id="reference"></a>
## Reference

Please see REFERENCE.md for the reference documentation.

This module is documented using Puppet Strings.

For a quick primer on how Strings works, please see [this blog post](https://puppet.com/blog/using-puppet-strings-generate-great-documentation-puppet-modules) or the [README.md](https://github.com/puppetlabs/puppet-strings/blob/master/README.md) for Puppet Strings.

To generate documentation locally, run the following command:
```
bundle install
bundle exec puppet strings generate ./lib/**/*.rb
```
This command will create a browsable `_index.html` file in the `doc` directory. The references available here are all generated from YARD-style comments embedded in the code base. When any development happens on this module, the impacted documentation should also be updated.

<a id="development"></a>
## Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide](https://puppet.com/docs/puppet/latest/contributing.html).

# Kmod Puppet module

[![Puppet Forge Version](http://img.shields.io/puppetforge/v/camptocamp/kmod.svg)](https://forge.puppetlabs.com/camptocamp/kmod)
[![Puppet Forge Downloads](http://img.shields.io/puppetforge/dt/camptocamp/kmod.svg)](https://forge.puppetlabs.com/camptocamp/kmod)
[![Build Status](https://img.shields.io/travis/camptocamp/puppet-kmod/master.svg)](https://travis-ci.org/camptocamp/puppet-kmod)
[![Puppet Forge Endorsement](https://img.shields.io/puppetforge/e/camptocamp/kmod.svg)](https://forge.puppetlabs.com/camptocamp/kmod)
[![Gemnasium](https://img.shields.io/gemnasium/camptocamp/puppet-kmod.svg)](https://gemnasium.com/camptocamp/puppet-kmod)
[![By Camptocamp](https://img.shields.io/badge/by-camptocamp-fb7047.svg)](http://www.camptocamp.com)

## Description

This module provides definitions to manipulate modprobe.conf (5) stanzas:

 * kmod::alias
 * kmod::install
 * kmod::blacklist

It depends on Augeas with the modprobe lens.

## Usage

This module has five main defined types:

  * kmod::load
  * kmod::alias
  * kmod::option
  * kmod::install
  * kmod::blacklist


### kmod::load

Loads a module using modprobe and manages persistent modules in /etc/sysconfig/modules

```puppet
  kmod::load { 'mymodule': }
```

### kmod::alias

Adds an alias to modprobe.conf, by default `/etc/modprobe.d/<name>.conf` is assumed for a filename.

```puppet
  kmod::alias { 'bond0':
    modulename => 'bonding',
  }
```

Params:
* `modulename`: Name of the module to alias
* `aliasname`: Name of the alias (defaults to the resource title)
* `file`: File to write to (see above default)

### kmod::option

Adds an option to modprobe.conf

```puppet
  kmod::option { 'bond0 mode':
    module  => 'bond0',
    option  => 'mode',
    value   => '1',
  }

  kmod::option { 'bond0':
    option => 'mode',
    value  => '1',
  }
```

Params:
* `option`: Name of the parameter to add
* `value`: Value of the parameter
* `module`: Name of the module (if ommited, the resource title is used)
* `file`: File to write to (defaults to `/etc/modprobe.d/<module name>.conf`)

### kmod::blacklist

Manages modprobe blacklist entries. Blacklist entries prevents module aliases from being used, 
but would not prevent the module from being loaded.
To prevent a module from being loaded use `kmod::install`

```puppet
  kmod::blacklist { 'foo': }
```

Params:
* `file`: File to write to, defaults to `/etc/modprobe.d/blacklist.conf`

### kmod::install

Manage modprobe install entries

```puppet
   kmod::install { 'pcspkr': }
```

If you want to ensure that module can't be loaded at all you can do the following:
```puppet
   kmod::install { 'dccp': command => '/bin/false' }
```

Params:
* `file`: File to write to (defaults to `/etc/modprobe.d/<module name>.conf`)
* `command`: (optional) command associated with the install, defaults to `/bin/true`



## Contributing

Please report bugs and feature request using [GitHub issue
tracker](https://github.com/camptocamp/puppet-kmod/issues).

For pull requests, it is very much appreciated to check your Puppet manifest
with [puppet-lint](https://github.com/camptocamp/puppet-kmod/issues) to follow the recommended Puppet style guidelines from the
[Puppet Labs style guide](http://docs.puppetlabs.com/guides/style_guide.html).

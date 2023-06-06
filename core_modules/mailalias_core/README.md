# mailalias

[![Modules Status](https://github.com/puppetlabs/puppetlabs-mailalias_core/workflows/%5BDaily%5D%20Unit%20Tests%20with%20nightly%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mailalias_core/actions)
[![Modules Status](https://github.com/puppetlabs/puppetlabs-mailalias_core/workflows/Static%20Code%20Analysis/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mailalias_core/actions) 
[![Modules Status](https://github.com/puppetlabs/puppetlabs-mailalias_core/workflows/Unit%20Tests%20with%20nightly%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mailalias_core/actions) 
[![Modules Status](https://github.com/puppetlabs/puppetlabs-mailalias_core/workflows/Unit%20Tests%20with%20released%20Puppet%20gem/badge.svg?branch=main)](https://github.com/puppetlabs/puppetlabs-mailalias_core/actions)


#### Table of Contents

1. [Description](#description)
2. [Usage - Configuration options and additional functionality](#usage)
3. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

<a id="description"></a>
## Description

The mailalias module is used to manage entries in the local alias database.

### Beginning with mailalias
To manage a mail alias, add the mailalias type to a class:
```puppet
mailalias { 'ftp':
  ensure    => present,
  recipient => 'root',
}
```
This example will redirect mail for the ftp account to root's mailbox.

<a id="usage"></a>
## Usage
The mailalias module is used to manage entries in `/etc/aliases`, which creates an email alias in the local alias database.

For details on usage, please see REFERENCE.md for the reference documentation.

#### file
A file containing the alias’s contents. The file and the recipient entries are mutually exclusive.
```puppet
mailalias { 'usenet':
  ensure => present,
  file   => '/tmp/foo/usenet-alias',
}
```
This will result in an entry such as `usenet: :include: /tmp/foo/usenet-alias`

#### recipient
Where email should be sent. Multiple values should be specified as an array. The file and the recipient entries are mutually exclusive.
```puppet
mailalias { 'ftp':
  ensure    => present,
  recipient => 'root',
}
```
This will result in an entry such as  `ftp: root`

#### target
The file in which to store the aliases. Only used by those providers that write to disk.
```puppet
mailalias { 'ftp':
  ensure    => present,
  recipient => 'root',
  target    => `/etc/mail/aliases`
}
```
This will ensure the entry exists in the file specified, such as:
```sh-session
$ cat /etc/mail/aliases
ftp: root
```

<a id="reference"></a>
## Reference

This module is documented using Puppet Strings.

For a quick primer on how Strings works, please see [this blog post](https://puppet.com/blog/using-puppet-strings-generate-great-documentation-puppet-modules) or the [README.md](https://github.com/puppetlabs/puppet-strings/blob/master/README.md) for Puppet Strings.

To generate documentation locally, run
```
bundle install
bundle exec puppet strings generate ./lib/**/*.rb
```
This command will create a browsable `\_index.html` file in the `doc` directory. The references available here are all generated from YARD-style comments embedded in the code base. When any development happens on this module, the impacted documentation should also be updated.

<a id="limitations"></a>
## Limitations

This module is only supported on platforms that have `sendmail` available.

<a id="development"></a>
## Development

Puppet Labs modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. We can't access the huge number of platforms and myriad of hardware, software, and deployment configurations that Puppet is intended to serve.

We want to keep it as easy as possible to contribute changes so that our modules work in your environment. There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things.

For more information, see our [module contribution guide.](https://docs.puppetlabs.com/forge/contributing.html)

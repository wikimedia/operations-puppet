# postfix

[![Build Status](https://img.shields.io/github/workflow/status/bodgit/puppet-postfix/Test)](https://github.com/bodgit/puppet-postfix/actions?query=workflow%3ATest)
[![Codecov](https://img.shields.io/codecov/c/github/bodgit/puppet-postfix)](https://codecov.io/gh/bodgit/puppet-postfix)
[![Puppet Forge version](http://img.shields.io/puppetforge/v/bodgit/postfix)](https://forge.puppetlabs.com/bodgit/postfix)
[![Puppet Forge downloads](https://img.shields.io/puppetforge/dt/bodgit/postfix)](https://forge.puppetlabs.com/bodgit/postfix)
[![Puppet Forge - PDK version](https://img.shields.io/puppetforge/pdk-version/bodgit/postfix)](https://forge.puppetlabs.com/bodgit/postfix)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with postfix](#setup)
    * [Beginning with postfix](#beginning-with-postfix)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module manages Postfix.

CentOS, RHEL, Scientific and Oracle Enterprise Linux is supported using Puppet
5 or later.

## Setup

### Beginning with postfix

Configure Postfix with the defaults as shipped by the OS and managing any
aliases using the standard Puppet `mailalias` resource type:

```puppet
include postfix

postfix::lookup::database { '/etc/aliases':
  type => 'hash',
}

Mailalias <||> -> Postfix::Lookup::Database['/etc/aliases']
```

## Usage

Configure Postfix with an additional submission service running on TCP port
587:

```puppet
include postfix

postfix::master { 'submission/inet':
  private => 'n',
  chroot  => 'n',
  command => 'smtpd -o smtpd_tls_security_level=encrypt -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject',
}
```

Configure Postfix for virtual mailbox hosting using LDAP to provide the
various lookup tables:

```puppet
class { 'postfix':
  virtual_mailbox_base    => '/var/mail/vhosts',
  virtual_mailbox_domains => ['ldap:/etc/postfix/virtualdomains.cf'],
  virtual_mailbox_maps    => ['ldap:/etc/postfix/virtualrecipients.cf'],
  virtual_minimum_uid     => 100,
  virtual_uid_maps        => 'static:5000',
  virtual_gid_maps        => 'static:5000',
}

# Specify connection defaults to enable sharing as per LDAP_README
Postfix::Lookup::Ldap {
  server_host => ['ldap://192.0.2.1'],
  search_base => 'dc=example,dc=com',
  bind_dn     => 'cn=Manager,dc=example,dc=com',
  bind_pw     => 'secret',
  version     => 3,
}

postfix::lookup::ldap { '/etc/postfix/virtualdomains.cf':
  query_filter     => '(associatedDomain=%s)',
  result_attribute => ['associatedDomain'],
}

postfix::lookup::ldap { '/etc/postfix/virtualrecipients.cf':
  query_filter     => '(mail=%s)',
  result_attribute => ['mail'],
}
```

Extend the above example to use `dovecot-lda(1)` instead of `virtual(8)`:

```puppet
include dovecot

class { 'postfix':
  virtual_transport       => 'dovecot'
  virtual_mailbox_domains => ['ldap:/etc/postfix/virtualdomains.cf'],
  virtual_mailbox_maps    => ['ldap:/etc/postfix/virtualrecipients.cf'],
}

postfix::main { 'dovecot_destination_recipient_limit':
  value => 1,
}

postfix::master { 'dovecot/unix':
  chroot       => 'n',
  command      => 'pipe flags=DRhu user=vmail:vmail argv=/path/to/dovecot-lda -f ${sender} -d ${recipient}',
  unprivileged => 'n',
  require      => Class['dovecot'],
}

# Specify connection defaults to enable sharing as per LDAP_README
Postfix::Lookup::Ldap {
  server_host => ['ldap://192.0.2.1'],
  search_base => 'dc=example,dc=com',
  bind_dn     => 'cn=Manager,dc=example,dc=com',
  bind_pw     => 'secret',
  version     => 3,
}

postfix::lookup::ldap { '/etc/postfix/virtualdomains.cf':
  query_filter     => '(associatedDomain=%s)',
  result_attribute => ['associatedDomain'],
}

postfix::lookup::ldap { '/etc/postfix/virtualrecipients.cf':
  query_filter     => '(mail=%s)',
  result_attribute => ['mail'],
}
```

## Reference

The reference documentation is generated with
[puppet-strings](https://github.com/puppetlabs/puppet-strings) and the latest
version of the documentation is hosted at
[https://bodgit.github.io/puppet-postfix/](https://bodgit.github.io/puppet-postfix/)
and available also in the [REFERENCE.md](https://github.com/bodgit/puppet-postfix/blob/main/REFERENCE.md).

## Limitations

This module takes the (somewhat laborious) approach of creating parameters for
each `main.cf` setting rather than just pass in a large hash of settings,
which should result in more control.

The only settings deliberately excluded are the following:

* `${transport}_delivery_slot_cost`
* `${transport}_delivery_slot_discount`
* `${transport}_delivery_slot_loan`
* `${transport}_destination_concurrency_failed_cohort_limit`
* `${transport}_destination_concurrency_limit`
* `${transport}_destination_concurrency_negative_feedback`
* `${transport}_destination_concurrency_positive_feedback`
* `${transport}_destination_rate_delay`
* `${transport}_destination_recipient_limit`
* `${transport}_extra_recipient_limit`
* `${transport}_minimum_delivery_slots`
* `${transport}_recipient_limit`
* `${transport}_recipient_refill_delay`
* `${transport}_recipient_refill_limit`

For these, use the `postfix::main` defined type.

Because Postfix allows you to recursively define parameters in terms of other
parameters it makes validating values impossible unless that convention is
forbidden. Currently this module allows recursive parameter expansion and so
only validates that values are either strings or arrays (of strings).

Any setting that accepts a boolean `yes`/`no` value also accepts native Puppet
boolean values. Any multi-valued setting accepts an array of values.

For referring to other settings, ensure that the `$` is escaped appropriately
using either `\` or `''` to prevent Puppet expanding the variable itself.

This module has been built on and tested against Puppet 5 and higher.

The module has been tested on:

* Red Hat/CentOS Enterprise Linux 6/7/8

## Development

The module relies on [PDK](https://puppet.com/docs/pdk/1.x/pdk.html) and has
both [rspec-puppet](http://rspec-puppet.com) and
[Litmus](https://github.com/puppetlabs/puppet_litmus) tests. Run them
with:

```
$ bundle exec rake spec
$ bundle exec rake litmus:*
```

Please log issues or pull requests at
[github](https://github.com/bodgit/puppet-postfix).

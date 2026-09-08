# puppet-rspamd

[![Build Status](https://github.com/markt-de/puppet-rspamd/actions/workflows/ci.yaml/badge.svg)](https://github.com/markt-de/puppet-rspamd/actions/workflows/ci.yaml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/markt/rspamd.svg)](https://forge.puppetlabs.com/markt/rspamd)
[![Puppet Forge](https://img.shields.io/puppetforge/dt/markt/rspamd.svg)](https://forge.puppetlabs.com/markt/rspamd)

#### Table of Contents

1. [Description](#description)
1. [Setup](#setup)
    * [What rspamd affects](#what-rspamd-affects)
    * [Beginning with rspamd](#beginning-with-rspamd)
1. [Usage](#usage)
1. [Reference](#reference)
1. [Development](#development)
    - [Contributing](#contributing)

## Description

This module installs and manages the Rspamd spam filter, and provides resources
and functions to configure the Rspamd system. 
It does, however, not configure the systems beyond the upstream defaults.

Please note that while all versions starting from 1.6.3 should still be
supported, this module is intended to be run with the latest version of Rspamd,
and compatibility with older versions will not be tested for new releases.

## Setup

### What rspamd affects

By default, this module...

* installs the rspamd.com package repository for Debian/Ubuntu and RHEL/CentOS/Fedora
* installs the rspamd package
* recursively purges all custom rspamd config (e.g. local.d and override.d directories)

### Beginning with rspamd

The simplest way to use this module is:

```puppet
include rspamd
```

This will setup the rspamd service the upstream default configuration.

## Usage

The rspamd::config resource can be used to specify custom configuration entries.
The easiest way to use it, is to put both the file and the hierachical config
key into the resource title:

```puppet
class { 'rspamd': }
rspamd::config {
  'classifier-bayes:backend': value => 'redis';
  'classifier-bayes:servers': value => '127.0.0.1:6379';
  'classifier-bayes:statfile[0].symbol': value => 'BAYES_HAM';
  'classifier-bayes:statfile[0].spam':   value => false;
  'classifier-bayes:statfile[1].symbol': value => 'BAYES_SPAM';
  'classifier-bayes:statfile[1].spam':   value => true;
}
```

This results the following config file `/etc/rspamd/local.d/classifier-bayes.conf`:

```
# This file is managed by Puppet. DO NOT EDIT.
backend = redis;
servers = "127.0.0.1:6379";
statfile {
  spam = false;
  symbol = 'BAYES_HAM';
}
statfile {
  spam = true;
  symbol = 'BAYES_SPAM';
}
```

Using the rspamd `$config` parameter, values for multiple config files can
easily be provided from hiera:

```yaml
rspamd::config:
  classifier-bayes:
    backend: redis
    servers: "127.0.0.1:6379"
    statfile:
      - symbol: BAYES_HAM
        spam: false
      - symbol: BAYES_SPAM
        spam: true
  milter_headers:
    use:
      - authentication-results
      - x-spam-status
  'worker-proxy.inc':
    bind_socket: 'localhost:11332'
    upstream:
      local:
        self_scan: true
  dkim_signing:
    sign_local: true
```

This uses the provided `rspamd::create_config_resources` and `rspamd::create_config_file_resources`
functions, which can be used in custom profiles for extended use cases:

```puppet
class profile::mail::rspamd (
  Hash $config,
  Hash $override_config,
) {
  class { 'rspamd': }

  rspamd::create_config_file_resources($config)
  rspamd::create_config_file_resources($override_config, { mode => 'override' })
}
```


## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

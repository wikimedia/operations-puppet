<!-- SPDX-License-Identifier: Apache-2.0 -->
# squid Puppet Module #

A Puppet module for installing and managing the Squid software.
It is very generic in nature, just installing the packages and making
sure the service runs. The configuration file is entirely up to you,
either via a template that gets evaluated in the calling class or
directly a configuration file

## Requirements ##
- Debian
- An understanding of the Squid software

## Notes ##

The module relies on you providing the configuration file

## Usage ##

    class { 'squid':
        config_source => 'puppet:///files/squid.conf',
    }

or

    class { 'squid':
        config_content => template('squid.conf.erb'),
    }

and you are set

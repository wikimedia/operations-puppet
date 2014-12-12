# squid3 Puppet Module #

A Puppet module for installing and managing the squid3 software.
It is very generic in nature, just installing the packages and making
sure the service runs. The configuration file is entirely up to you,
either via a template that gets evaluated in the calling class or
directly a configuration file

## Requirements ##
- A Debian like distro (e.g. Ubuntu)
- An understanding of the squid3 software

## Notes ##

The module relies on you providing the configuration file

## Usage ##

    class { 'squid3':
        config_source => 'puppet:///files/squid3.conf',
    }

or

    class { 'squid3':
        config_content => template('squid.conf.erb'),
    }

and you are set

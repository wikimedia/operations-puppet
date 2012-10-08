# mongodb puppet module

## Overview

Installs mongodb on Ubuntu/Debian from OS repo, or alternatively per 10gen [installation documentation](http://www.mongodb.org/display/DOCS/Ubuntu+and+Debian+packages).

## Usage

### class mongodb

Parameters:
* enable_10gen (default: false) - Whether or not to set up 10gen software repositories
* init (auto discovered) - override init (sysv or upstart) for Debian derivatives
* location - override apt location configuration for Debian derivatives
* packagename (auto discovered) - override the package name
* servicename (auto discovered) - override the service name

By default ubuntu is upstart and debian uses sysv.

Examples:

    class mongodb {
      init => 'sysv',
    }

    class mongodb {
      enable_10gen => true,
    }

## Supported Platforms

* Debian Wheezy
* Ubuntu 12.04 (precise)
* RHEL 6

## Note:
This module was originally cloned fromhttps://github.com/puppetlabs/puppetlabs-mongodb at commit 691620d9058e7b41110793abe59442c4d463d568.  It has been modified to suit WMF defaults.
# Backups Puppet Module #

A Puppet module for deduplicating configuration puppet stanzas for WMF
The bacula puppet module is generic enough to allow being used by third
parties. At the same time however some simple defines must be used to
deduplicate stuff and allow easy of use. This module contains that,
mostly WMF specific code

## Requirements ##
- The bacula puppet module and whatever that requires

## Notes ##

The idea behind this module is to make it extra easy to get a host up
and running in WMF backups.


## Usage ##

include profile::backup::host
backup::set { 'home': }

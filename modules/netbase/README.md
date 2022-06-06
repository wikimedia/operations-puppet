<!-- SPDX-License-Identifier: Apache-2.0 -->
# Service Definitions
This module is used to manage the services definitions in /etc/services

The modules uses a in module hieradata for the default set of port definitions
which it pulls directly from the debian netbase salsa repo[1].  The defaults
can be updated by running the following

```
bundle exec rake update_hieradata
```


[1]https://salsa.debian.org/md/netbase/-/raw/master/etc/services

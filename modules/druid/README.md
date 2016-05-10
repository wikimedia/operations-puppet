# Druid Puppet Module

This module works with the Druid debian packaging from.
https://gerrit.wikimedia.org/r/#/admin/projects/operations/debs/druid, and only
on systems with systemd.

Druid `common.runtime.properties` are configured via the main `druid`
init class.

Each Druid service is parameterized via the hashes `$properties` and
`$env`.  `$properties` will be rendered into
`/etc/druid/$service/runtime.properties`.  These will be picked up by
an individual Druid service. `$env` will be rendered into
`/etc/druid/$service/$env.sh`.  These shell environment variables will be
sourced by the systemd unit that starts the service.

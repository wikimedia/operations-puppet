# == Class: role::toollabs::legacy
#
# Supports redirects and aliases for old toolserver references.
#
class role::toollabs::legacy {
    include ::toolserver_legacy
}

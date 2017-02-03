# == Class: role::toollabs::legacy
#
# Supports redirects and aliases for old toolserver references.
#
# filtertags: labs-project-toolserver-legacy
class role::toollabs::legacy {
    include ::toolserver_legacy
}

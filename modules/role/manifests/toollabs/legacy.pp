# == Class: role::toollabs::legacy
#
# Supports redirects and aliases for old toolserver references.
#
# filtertags: wmcs-project-toolserver-legacy

# TODO: delete this after the VM is switched to role::wmcs::toolserver_legacy
class role::toollabs::legacy {
    system::role { $name: }

    include ::profile::wmcs::toolserver_legacy
}

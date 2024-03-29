# SPDX-License-Identifier: Apache-2.0
# @summary install production specific classes
# @param enable weather to enable or disabl this profile.  This is most often used to disable this profile
#   in cloud environments which directly include a role:: class
# @param enable_ip6_mapped if ipv6 mapped addresses should be enabled
# @param role_description A role description to add to the motd
class profile::base::production (
    Boolean $enable                       = lookup('profile::base::production::enable'),
    Boolean $enable_ip6_mapped            = lookup('profile::base::production::enable_ip6_mapped'),
    Optional[String[1]] $role_description = lookup('profile::base::production::role_description')
) {
    if $enable {
        # include this early so we can use the data elsewhere
        include profile::netbox::host
        include profile::base
        # Contain the profile::admin module so we create all the required groups before
        # something else creates a system group with one of our GID's
        # e.g. ::profile::debmonitor::client
        contain profile::admin

        include profile::pki::client
        # profile::base::certificates provides the ca file used by the pki client
        Class['profile::base::certificates'] -> Class['profile::pki::client']
        include profile::contacts
        include profile::base::netbase
        include profile::logoutd
        include profile::cumin::target
        include profile::debmonitor::client

        class { 'base::phaste': }
        class { 'base::screenconfig': }

        if debian::codename::le('buster') {
            class { 'toil::acct_handle_wtmp_not_rotated': }
        }
        include profile::monitoring
        include profile::rsyslog::kafka_shipper

        include profile::emacs

        if $enable_ip6_mapped {
            interface::add_ip6_mapped { 'main': }
        }

        if $facts['has_ipmi'] {
            class { 'prometheus::ipmi_exporter': }
        }

        if $facts['is_virtual'] {
            class { 'toil::ganeti_ifupdown': }
        }
        $role_str = $::_role.regsubst('\/', '::', 'G') # lint:ignore:top_scope_facts
        $message = $role_description ? {
            undef   => "${facts['networking']['hostname']} is ${role_str}",
            default => "${facts['networking']['hostname']} is a ${role_description} (${role_str})",
        }
        motd::message { $role_str:
            priority => 5,
            message  => $message,
        }
    }
}

# SPDX-License-Identifier: Apache-2.0
# @summary install production specific classes
# @param enable weather to enable or disabl this profile.  This is most often used to disable this profile
#   in cloud environments which directly include a role:: class
# @param enable_ip6_mapped if ipv6 mapped addresses should be enabled
class profile::base::production (
    Boolean $enable            = lookup('profile::base::production::enable'),
    Boolean $enable_ip6_mapped = lookup('profile::base::production::enable_ip6_mapped'),
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

        # we backported prometheus-ipmi-exporter to buster
        if $facts['has_ipmi'] and debian::codename::ge('buster') {
            class { 'prometheus::ipmi_exporter': }
        }
    }
}

# == Class standard
# Class for *most* servers, standard includes

class standard(
    $has_default_mail_relay = true,
    Array[String] $monitoring_hosts = [],
    ) {
    include ::profile::base
    include ::standard::ntp

    if $::realm == 'production' {
        # Include this first so we create all the required groups before
        # something else creates a system group with one of our GID's
        # e.g. ::profile::debmonitor::client
        contain ::admin
        include ::profile::cumin::target
        include ::profile::debmonitor::client  # lint:ignore:wmf_styleguide
    }

    unless $::fqdn in $::ntp_peers[$::site] {
        include ::standard::ntp::timesyncd
    }

    include ::standard::prometheus

    # Some instances have their own exim definition that
    # will conflict with this
    if $has_default_mail_relay {
        include ::standard::mail::sender
    }

    # For historical reasons, users in modules/admin/data/data.yaml
    # (for production) and in LDAP (for Labs) start at uid/gid 500, so
    # we need to guard against system users being created in that
    # range.
    file_line { 'login.defs-SYS_UID_MAX':
        path  => '/etc/login.defs',
        match => '#?SYS_UID_MAX\b',
        line  => 'SYS_UID_MAX               499',
    }
    file_line { 'login.defs-SYS_GID_MAX':
        path  => '/etc/login.defs',
        match => '#?SYS_GID_MAX\b',
        line  => 'SYS_GID_MAX               499',
    }
}

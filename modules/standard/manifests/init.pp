# == Class standard
# Class for *most* servers, standard includes

class standard(
    $has_default_mail_relay = true,
    $has_admin = true,
    $has_ganglia = true,
    ) {
    include ::profile::base
    include ::standard::ntp

    if $::realm == 'production' {
        include ::profile::cumin::target
    }

    unless $::fqdn in $::standard::ntp::wmf_peers[$::site] {
        if (os_version('debian >= jessie')) {
            include ::standard::ntp::timesyncd
        } else {
            include ::standard::ntp::client
        }
    }

    include ::standard::diamond
    include ::standard::prometheus

    include ::ganglia::monitor::decommission

    # Some instances have their own exim definition that
    # will conflict with this
    if $has_default_mail_relay {
        include ::standard::mail::sender
    }

    # Some instances in production (ideally none) and labs do not use
    # the admin class
    if $has_admin {
        include ::admin
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

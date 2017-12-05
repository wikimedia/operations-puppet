# == Class standard
# Class for *most* servers, standard includes
# Standard is properly a profile. Given its special nature, it has been
# historically separated and we're keeping it that way for now.
class standard(
    # lint:ignore:wmf_styleguide
    $has_default_mail_relay = hiera('standard::has_default_mail_relay', true),
    $has_admin = hiera('standard::has_admin', true),
    $has_ganglia = hiera('standard::has_ganglia', true),
    $admin_groups = hiera('admin::groups', [])
    # lint:endignore
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

    if $has_ganglia {
        include ::ganglia
    } else {
        include ::ganglia::monitor::decommission
    }

    # Some instances have their own exim definition that
    # will conflict with this
    if $has_default_mail_relay {
        include ::standard::mail::sender
    }

    # Some instances in production (ideally none) and labs do not use
    # the admin class
    if $has_admin {
        class { '::admin':
            groups => $admin_groups
        }
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

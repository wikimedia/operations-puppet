class profile::standard(
    Boolean                    $has_default_mail_relay = lookup('profile::standard::has_default_mail_relay'),
    Array[Stdlib::IP::Address] $monitoring_hosts       = lookup('monitoring_hosts'),
    Boolean                    $enable_ip6_mapped      = lookup('profile::standard::enable_ip6_mapped'),
    Boolean                    $purge_sudoers_d        = lookup('profile::standard::purge_sudoers_d'),
    Array[String]              $admin_groups           = lookup('profile::standard::admin_groups'),
    Array[String]              $admin_groups_no_ssh    = lookup('profile::standard::admin_groups_no_ssh'),
) {
    include profile::base
    if $::realm == 'production' {
        class {'sudo':
            purge_sudoers_d => $purge_sudoers_d,
        }
        class {'admin':
            groups        => $admin_groups,
            groups_no_ssh => $admin_groups_no_ssh,
        }
        # Contain the admin module so we create all the required groups before
        # something else creates a system group with one of our GID's
        # e.g. ::profile::debmonitor::client
        contain admin # lint:ignore:wmf_styleguide
        include profile::cumin::target
        include profile::debmonitor::client

    }
    class { 'standard':
        has_default_mail_relay => $has_default_mail_relay,
        monitoring_hosts       => $monitoring_hosts,
    }
    if $enable_ip6_mapped {
        interface::add_ip6_mapped { 'main': }
    }
}

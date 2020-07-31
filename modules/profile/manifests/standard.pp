class profile::standard(
    Boolean                    $has_default_mail_relay = lookup('profile::standard::has_default_mail_relay'),
    Array[Stdlib::IP::Address] $monitoring_hosts       = lookup('monitoring_hosts'),
    Boolean                    $enable_ip6_mapped      = lookup('profile::standard::enable_ip6_mapped'),
) {
    include profile::base
    if $::realm == 'production' {
        class {'admin': }
        # Contain the admin module so we create all the required groups before
        # something else creates a system group with one of our GID's
        # e.g. ::profile::debmonitor::client
        contain admin  # lint:ignore:wmf_styleguide
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

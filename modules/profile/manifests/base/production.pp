class profile::base::production (
    Boolean $enable_ip6_mapped = lookup('profile::base::production::enable_ip6_mapped'),
) {
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
    include profile::emacs

    if $enable_ip6_mapped {
        interface::add_ip6_mapped { 'main': }
    }
}

class role::ganeti_test {
    include profile::base::production
    include profile::firewall

    include profile::ganeti
}

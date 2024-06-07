class role::pontoon::lb {
    include profile::base::production
    include profile::firewall
    include profile::pontoon::lb
}

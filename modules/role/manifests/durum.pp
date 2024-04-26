class role::durum {
    include profile::base::production
    include profile::firewall
    include profile::durum
    include profile::nginx
    include profile::bird::anycast
}

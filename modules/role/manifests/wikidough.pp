class role::wikidough {
    include profile::base::production
    include profile::firewall
    include profile::wikidough
    include profile::bird::anycast
}

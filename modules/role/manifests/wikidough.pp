class role::wikidough {

    system::role { 'wikidough':
        description => 'DoH and DoT Resolver'
    }

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::wikidough
    include ::profile::bird::anycast

}

class role::wikidough {

    system::role { 'wikidough':
        description => 'DoH and DoT Resolver'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::wikidough
    include ::profile::bird::anycast

}

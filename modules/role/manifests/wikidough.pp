class role::wikidough {

    system::role { 'wikidough':
        description => 'Experimental DoH Resolver'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::wikidough

}

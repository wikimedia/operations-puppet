class role::durum {

    system::role { 'durum':
        description => 'Check service for Wikidough'
    }

    include profile::standard
    include profile::base::firewall

}

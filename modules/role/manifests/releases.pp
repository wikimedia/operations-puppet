class role::releases {

    system::role { 'releases':
        ensure      => 'present',
        description => 'Wikimedia Software Releases Server',
    }

    include ::standard
    include ::base::firewall
    include ::profile::backup::host
    include ::profile::releases::mediawiki
}

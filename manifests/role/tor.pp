class role::tor {

    system::role { 'tor':
        description => 'Tor relay'
    }

    class { '::tor':
        tor_controlport => '9051',
        tor_orport      => '9001',
        tor_dirport     => '9030',
        tor_address     => 'tor.wikimedia.org',
        tor_nickname    => 'wikimedia',
        tor_contact     => 'noc@wikimedia.org',
    }

}

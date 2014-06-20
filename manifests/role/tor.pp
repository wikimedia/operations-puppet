class role::tor {

    system::role { 'tor':
        description => 'Tor relay'
    }

    class { '::tor':
        tor_controlport => '9051',
        tor_orport      => '9001',
        tor_dirport     => '9030',
        tor_address     => 'tor-eqiad-1.wikimedia.org',
        tor_nickname    => 'wikimedia-eqiad-1',
        tor_contact     => 'noc@wikimedia.org',
        tor_exit_policy => 'reject *:*', # no exits allowed
    }

}

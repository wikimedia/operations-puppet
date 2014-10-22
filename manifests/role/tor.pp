class role::tor {

    system::role { 'tor':
        description => 'Tor relay'
    }

    include passwords::tor

    class { '::tor':
        tor_controlport => '9051',
        tor_orport      => '443',
        tor_dirport     => '80',
        tor_address     => 'tor-eqiad-1.wikimedia.org',
        tor_nickname    => 'wikimediaeqiad1',
        tor_contact     => 'noc@wikimedia.org',
        tor_exit_policy => 'reject *:*', # no exits allowed
    }

}

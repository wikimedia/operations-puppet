class role::beta::trebuchet_testing {
    system::role { 'role::beta::trebuchet_testing':
        description => 'Trebuchet testing host'
    }

    include ::beta::config
    package { 'test/testrepo':
        provider => 'trebuchet',
    }


    # Allow ssh inbound from deployment-bastion.eqiad.wmflabs for testing
    ferm::rule { 'deployment-bastion-trebuchet-testing-ssh':
        ensure => present,
        rule   => "proto tcp dport ssh saddr ${::beta::config::bastion_ip} ACCEPT;",
    }
}


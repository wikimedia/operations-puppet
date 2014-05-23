class role::puppet_compiler {

    system::role { 'role::puppet_compiler': description => 'Puppet compiler jenkins slave'}

    case $::realm {
        'labs'      : {
            require role::ci::slave::labs::common
            ferm::rule {'puppet_compiler_web':
                ensure => present,
                rule   => 'proto tcp dport http mod state state NEW { saddr $INTERNAL ACCEPT; }'
            }
        }
        'production': { require role::ci::slave }
        default     : { fail("Realm ${::realm} NOT supported by this role.") }
    }

    class {'::puppet_compiler':
        ensure  => 'present',
        version => '0.2.2',
        user    => 'jenkins-deploy',
    }

}

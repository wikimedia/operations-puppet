class role::puppet_compiler {

    system::role { 'role::puppet_compiler': description => 'Puppet compiler jenkins slave'}

    case $::realm {
        'labs'      : {
            require role::ci::slave::labs::common
            ferm::service {'puppet_compiler_web':
                ensure => 'present',
                proto  => 'tcp',
                port   => 'http',
                prio   => '30',
                srange => '\$INTERNAL'
            }
        }
        'production': { require role::ci::slave }
        default     : { fail("Realm ${::realm} NOT supported by this role.") }
    }

    class {'::puppet_compiler':
        ensure  => 'present',
        version => '0.3',
        user    => 'jenkins-deploy',
    }

}

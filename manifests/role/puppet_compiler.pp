class role::puppet_compiler {

    system::role { 'role::puppet_compiler': description => 'Puppet compiler jenkins slave'}

    case $::realm {
        'labs'      : { require role::ci::slave::labs::common }
        'production': { require role::ci::slave }
        default     : { fail("Realm ${::realm} NOT supported by this role.") }
    }

    class {'::puppet_compiler':
        ensure  => 'present',
        version => '0.2.1',
        user    => 'jenkins-deploy',
    }

}

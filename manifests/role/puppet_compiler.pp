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
        default     : { fail("Realm ${::realm} NOT supported by this role.") }
    }

    class {'::puppet_compiler':
        ensure  => 'present',
        version => '0.3',
        user    => 'jenkins-deploy',
    }

    file { '/mnt/puppet-compiler-output':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        require => $::role::ci::slave::labs::common::slash_mnt_require
    }

    mount { "${::puppet_compiler::program_dir}/output":
        ensure  => mounted,
        type    => 'auto',
        options => 'bind',
        device  => '/mnt/puppet-compiler-output'
    }

    file { '/mnt/puppet-compiler-external':
        ensure  => directory,
        owner   => 'jenkins-deploy',
        require => $::role::ci::slave::labs::common::slash_mnt_require
    }

    mount { "${::puppet_compiler::program_dir}/external/change":
        ensure  => mounted,
        type    => 'auto',
        options => 'bind',
        device  => '/mnt/puppet-compiler-external'
    }

    cron { 'check_compiler_stale_repositories':
        command => '/usr/bin/find /mnt/puppet-compiler-external -mindepth 1 -maxdepth 1 -ctime +1 -type d | /usr/bin/xargs rm -rf',
        user    => 'jenkins-deploy',
        weekday => 0,
    }

    cron { 'check_compiler_stale_output':
        command => '/usr/bin/find /mnt/puppet-compiler-output -mindepth 1 -maxdepth 1 -ctime +10 -type d | /usr/bin/xargs rm -rf',
        user    => 'jenkins-deploy',
        weekday => 0,
    }

}

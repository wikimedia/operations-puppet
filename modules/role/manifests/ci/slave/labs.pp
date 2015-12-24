class role::ci::slave::labs {
    requires_realm('labs')

    system::role { 'role::ci::slave::labs':
        description => 'CI Jenkins slave on labs' }

    # Debian slaves are used to build Debian packages for all our distributions
    if os_version('debian >= jessie') {
        system::role { '::package_builder':
            description => 'CI package building',
        }
        class { '::package_builder':
            # We need /var/cache/pbuilder to be a symlink to /mnt
            # before cowbuilder/pbuilder is installed
            require => Class['contint::packages::labs'],
        }
    }

    file { '/srv/localhost-worker':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-deploy',
        group  => 'root',
    }
    include contint::worker_localhost

    contint::tmpfs { 'tmpfs for jenkins CI labs slave':
        # Jobs expect the tmpfs to be in $HOME/tmpfs
        mount_point => '/mnt/home/jenkins-deploy/tmpfs',
        size        => '512M',
        require     => File['/mnt/home/jenkins-deploy'],
    }

    # Trebuchet replacement on labs
    include contint::slave_scripts

    # Include package unsafe for production
    include contint::packages::labs

    if os_version('ubuntu >= trusty') {
        include contint::hhvm
    }

    include role::ci::slave::labs::common
    include role::zuul::install

    include role::ci::slave::localbrowser

    class { 'role::ci::slave::browsertests':
        require => [
            Class['role::ci::slave::labs::common'], # /mnt
            Class['contint::packages::labs'], # realize common packages first
        ]
    }

}


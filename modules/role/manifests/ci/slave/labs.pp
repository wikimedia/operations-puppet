# filtertags: labs-project-git labs-project-integration labs-project-ci-staging
class role::ci::slave::labs {
    requires_realm('labs')

    system::role { 'role::ci::slave::labs':
        description => 'CI Jenkins slave on labs' }

    # Some jobs push to Gerrit, eg for maven based releasing
    include ::role::gerrit::client

    # Debian slaves are used to build Debian packages for all our distributions
    if os_version('debian >= jessie') {
        system::role { '::package_builder':
            description => 'CI package building',
        }
        include ::contint::package_builder
    }

    class { 'contint::worker_localhost':
        owner => 'jenkins-deploy',
    }

    contint::tmpfs { 'tmpfs for jenkins CI labs slave':
        # Jobs expect the tmpfs to be in $HOME/tmpfs
        mount_point => '/mnt/home/jenkins-deploy/tmpfs',
        size        => '256M',
        require     => File['/mnt/home/jenkins-deploy'],
    }

    # Trebuchet replacement on labs
    include contint::composer
    include contint::phpunit
    include contint::slave_scripts

    # Include package unsafe for production
    include contint::packages::labs

    if os_version('ubuntu >= trusty') {
        include contint::hhvm
    }

    include contint::php

    include role::ci::slave::labs::common

    include ::zuul

    if os_version('ubuntu >= trusty || debian >= jessie') {
        include contint::browsers

        class { 'role::ci::slave::browsertests':
            require => [
                Class['role::ci::slave::labs::common'], # /mnt
                Class['contint::packages::labs'], # realize common packages first
            ]
        }
    }

    # Put the mysql-server db on tmpfs

    exec { 'create-var-lib-mysql-mountpoint':
        creates => '/var/lib/mysql',
        command => '/bin/mkdir -p /var/lib/mysql',
    }

    mount { '/var/lib/mysql':
        ensure  => mounted,
        atboot  => true,
        device  => 'none',
        fstype  => 'tmpfs',
        options => 'defaults,size=256M',
        require => Exec['create-var-lib-mysql-mountpoint'],
    }

    file { '/var/lib/mysql':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0775',
        require => Mount['/var/lib/mysql'],
    }

    exec { 'create-mysql-datadir':
        path    => '/bin:/usr/bin',
        creates => '/var/lib/mysql/.created',
        command => 'mysql_install_db --user=mysql --datadir=/var/lib/mysql && touch /var/lib/mysql/.created',
        require => [ File['/var/lib/mysql'], Package['mysql-server'] ],
    }

    file { '/etc/init/mysql.override':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "manual\n",
        require => Package['mysql-server'],
    }

    service { 'mysql':
        ensure   => running,
        enable   => true,
        # With the service being debian, which are the generic init independent
        # service wrappers create by debian and thus also work on ubuntu with
        # upstart, it won't instruct upstart to enable the service, thus not
        # reverting setting it to manual.
        provider => 'debian',
        require  => Exec['create-mysql-datadir'],
    }

}

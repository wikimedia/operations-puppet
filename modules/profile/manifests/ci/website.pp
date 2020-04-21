# Website for Continuous integration
#
# http://integration.wikimedia.org/
class profile::ci::website {

    # Apache configuration for integration.wikimedia.org
    httpd::site { 'integration.wikimedia.org':
        content => template('contint/apache/integration.wikimedia.org.erb'),
    }

    # Static files in these docroots are in integration/docroot.git

    file { '/srv/org':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }

    file { '/srv/org/wikimedia':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }
    file { '/srv/org/wikimedia/integration':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }

}

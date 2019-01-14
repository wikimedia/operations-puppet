# Website for Continuous integration
#
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class profile::ci::website {

    # Apache configuration for integration.wikimedia.org
    httpd::site { 'integration.wikimedia.org':
        content => template('contint/apache/integration.wikimedia.org.erb'),
    }

    # Apache configuration for integration.mediawiki.org
    httpd::site { 'integration.mediawiki.org':
        content => template('contint/apache/integration.mediawiki.org.erb'),
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

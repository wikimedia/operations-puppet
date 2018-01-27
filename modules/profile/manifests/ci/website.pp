# Website for Continuous integration
#
# http://doc.mediawiki.org/
# http://doc.wikimedia.org/
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class profile::ci::website {
    # Need to send Vary: X-Forwarded-Proto since most sites are forced to HTTPS
    # and behind a varnish cache. See also T62822
    class { '::apache::mod::headers': }
    class { '::apache::mod::rewrite': }

    # Apache configuration for integration.wikimedia.org
    apache::site { 'integration.wikimedia.org':
        content => template('contint/apache/integration.wikimedia.org.erb'),
    }

    # Apache configuration for integration.mediawiki.org
    apache::site { 'integration.mediawiki.org':
        content => template('contint/apache/integration.mediawiki.org.erb'),
    }

    # Apache configuration for doc.wikimedia.org
    apache::site { 'doc.wikimedia.org':
        content => template('contint/apache/doc.wikimedia.org.erb'),
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
    # MediaWiki code coverage
    file { '/srv/org/wikimedia/integration/coverage':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }

    # Jenkins console logs
    file { '/srv/org/wikimedia/integration/logs':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }

    # Written to by jenkins for automatically generated
    # documentations
    file { '/srv/org/wikimedia/doc':
        ensure => directory,
        mode   => '0775',
        owner  => 'jenkins-slave',
        group  => 'jenkins-slave',
    }

}

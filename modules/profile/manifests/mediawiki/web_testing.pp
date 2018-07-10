class profile::mediawiki::web_testing {
    # Perl helper script for apache changes
    require_package('libwww-perl')

    file  { '/usr/local/bin/apache-fast-test':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/web_testing/apache-fast-test',
    }

    # Copy the predefined test files for apache-fast-test
    file { '/usr/local/share/apache-tests':
        ensure  => directory,
        source  => 'puppet:///modules/profile/mediawiki/web_testing/tests',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    # Little automation to use on the cumin masters for deploying an apache config change
    file { '/usr/local/bin/deploy-apache-change':
        ensure => present,
        source => 'puppet:///modules/profile/mediawiki/web_testing/deploy_apache_change.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}

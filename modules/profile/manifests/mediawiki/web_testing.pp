class profile::mediawiki::web_testing {
    # Perl helper script for apache changes
    file  { '/usr/local/bin/apache-fast-test':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/web_testing/apache-fast-test',
    }

    # Formerly the predefined test files for apache-fast-test
    file { '/usr/local/share/apache-tests':
        ensure => absent,
        force  => true,
    }
}

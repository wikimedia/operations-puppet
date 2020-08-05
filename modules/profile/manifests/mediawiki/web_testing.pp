class profile::mediawiki::web_testing {
    # Formerly the Perl helper script for apache changes
    file  { '/usr/local/bin/apache-fast-test':
        ensure => absent,
    }

    # Formerly the predefined test files for apache-fast-test
    file { '/usr/local/share/apache-tests':
        ensure => absent,
        force  => true,
    }
}

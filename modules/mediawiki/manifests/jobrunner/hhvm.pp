class mediawiki::jobrunner::hhvm {
    # Install hhvm and all needed packages
    include mediawiki::packages::hhvm

    # Ensure the fcgi server is stopped
    service { 'hhvm':
        ensure   => stopped,
        provider => 'upstart'
    }

    # ensure hhvm is the chosen runtime for /usr/bin/php
    alternatives::config{ 'php':
        path        => '/usr/bin/hhvm',
        require     => Package['hhvm']
    }

    file { '/etc/hhvm':
        ensure  => directory,
        mode    => '0555',
        require => Package['hhvm']
    }

    file { '/etc/hhvm/config.hdf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/hhvm/jobrunner.hhvm.hdf',
    }

    file { '/etc/hhvm/hhvm.ini':
        ensure => present,
        source => 'puppet:///modules/mediawiki/hhvm/jobrunner.hhvm.ini',
    }

}

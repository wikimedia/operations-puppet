class contint::packages::hhvm {

    package { 'libcurl4-gnutls-dev':
        # Conflict with HHVM build dependency libcurl4-openssl-dev.
        # Was For pycurl which now build with openssl just fine.
        ensure =>  absent,
    }

    exec { '/usr/bin/apt-get -y build-dep hhvm':
        onlyif => '/usr/bin/apt-get -s build-dep hhvm | /bin/grep -Pq "will be (installed|upgraded)"',
    }
    package { ['hhvm-dev']:
        ensure => present,
    }

}

class contint::packages::hhvm {

    exec { '/usr/bin/apt-get -y build-dep hhvm':
        onlyif => '/usr/bin/apt-get -s build-dep hhvm | /bin/grep -Pq "will be (installed|upgraded)"',
    }
    package { ['hhvm-dev']:
        ensure => present,
    }

}

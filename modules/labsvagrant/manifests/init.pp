class labsvagrant {
    user { 'vagrant':
        ensure => 'present'
    }

    git::clone { 'vagrant':
        directory => '/vagrant/',
        origin => 'https://yuvipanda@gerrit.wikimedia.org/r/mediawiki/vagrant',
        ownder => 'vagrant',
        group => 'www-data',
        require => User['vagrant']
    }

    file { '/bin/vagrant-puppet-runner':
        ensure => 'puppet:///files/labsvagrant/vagrant-puppet-runner.bash',
        mode => 'a=rx,o=rwx',
        owner => 'root'
    }
}

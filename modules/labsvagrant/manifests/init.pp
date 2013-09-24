class labsvagrant {
    user { 'vagrant':
        ensure => 'present'
    }

    file { '/v/':
        ensure => 'directory',
        owner => 'vagrant',
        group => 'www-data',
        require => User['vagrant']
    }

    git::clone { '/v/vagrant':
        directory => '/v/vagrant/',
        origin => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
        owner => 'vagrant',
        group => 'www-data',
        require => File['/v/']
    }

    file { '/bin/vagrant-puppet-runner':
        ensure => 'present',
        source => 'puppet:///modules/labsvagrant/vagrant-puppet-runner.bash',
        mode => 'a=rx,o=rwx',
        owner => 'root'
    }
}

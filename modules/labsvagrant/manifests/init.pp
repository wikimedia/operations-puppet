class labsvagrant {
    user { 'vagrant':
        ensure => 'present'
    }

    git::clone { 'vagrant':
        directory => '/vagrant/',
        origin => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
        owner => 'vagrant',
        group => 'www-data',
        require => User['vagrant']
    }

    file { '/bin/vagrant-puppet-runner':
        ensure => 'present',
        source => 'puppet:///modules/labsvagrant/vagrant-puppet-runner.bash',
        mode => 'a=rx,o=rwx',
        owner => 'root'
    }
}

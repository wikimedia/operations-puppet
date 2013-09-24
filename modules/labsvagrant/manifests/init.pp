class labsvagrant {
    user { 'vagrant':
        ensure => 'present'
    }

    git::clone { 'vagrant':
        directory => '/vagrant/',
        origin => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant'
    }

    file { '/vagrant':
        recurse => true,
        owner => 'vagrant',
        group => 'www-data',
        require => [ User['vagrant'], Exec['git_clone_vagrant'] ]
    }

    file { '/bin/vagrant-puppet-runner':
        ensure => 'present',
        source => 'puppet:///modules/labsvagrant/vagrant-puppet-runner.bash',
        mode => 0755,
        owner => 'root'
    }
}

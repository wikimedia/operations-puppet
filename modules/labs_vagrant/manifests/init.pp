class labs_vagrant {
    user { 'vagrant':
        ensure => 'present',
        managehome => true
    }

    git::clone { 'vagrant':
        directory => '/mnt/vagrant/',
        origin => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant'
    }

    # /mnt has way more space than /
    file { '/mnt/vagrant':
        recurse => true,
        owner => 'vagrant',
        group => 'www-data',
        require => [ User['vagrant'], Exec['git_clone_vagrant'] ]
    }

    file { '/vagrant':
        ensure => 'link',
        target => '/mnt/vagrant',
        require => File['/mnt/vagrant']
    }

    file { '/bin/labs-vagrant':
        ensure => 'link',
        target => '/vagrant/lib/labs-vagrant.rb',
        mode => '0555',
        require => File['/vagrant']
    }
}

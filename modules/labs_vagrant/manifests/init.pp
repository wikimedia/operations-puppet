class labs_vagrant {
    user { 'vagrant':
        ensure     => 'present',
        home       => '/mnt/vagrant-user'
        managehome => true
    }

    file { '/etc/sudoers.d/vagrant':
        source  => 'puppet:///modules/labs_vagrant/vagrant-sudoers',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        require => User['vagrant'],
    }

    git::clone { 'vagrant':
        directory => '/mnt/vagrant/',
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
    }

    # /mnt has way more space than /
    file { '/mnt/vagrant':
        recurse => true,
        owner   => 'vagrant',
        group   => 'www-data',
        require => [ User['vagrant'], Exec['git_clone_vagrant'] ],
    }

    file { '/vagrant':
        ensure  => 'link',
        target  => '/mnt/vagrant',
        require => File['/mnt/vagrant'],
    }

    file { '/bin/labs-vagrant':
        ensure  => 'link',
        target  => '/vagrant/lib/labs-vagrant.rb',
        mode    => '0555',
        require => File['/vagrant'],
    }
}

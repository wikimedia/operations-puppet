class labsvagrant {
    user { 'vagrant':
        ensure => 'present'
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

    file { '/vagrant/':
        ensure => 'link',
        target => '/mnt/vagrant',
        require => File['/mnt/vagrant']
    }

    file { '/vagrant/lib/mediawiki-vagrant/labsgrant.rb':
        ensure => 'present',
        source => 'puppet:///modules/labsvagrant/labsvagrant.rb',
        mode => '0755',
        require => File['/vagrant']
    }

    file { '/bin/labsvagrant':
        ensure => 'link',
        target => '/vagrant/lib/mediawiki-vagrant/labsgrant.rb',
        mode => '0755',
        require => File['/vagrant/lib/mediawiki-vagrant/labsgrant.rb']
    }
}

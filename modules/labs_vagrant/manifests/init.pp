# == labs_vagrant
#
# Configure a labs host to use MediaWiki-Vagrant to manage local wikis
#
class labs_vagrant {
    user { 'vagrant':
        ensure     => 'present',
        home       => '/home/vagrant',
        managehome => true,
    }

    sudo::user { 'vagrant' :
        privileges => [
            'ALL=(ALL) NOPASSWD:ALL',
        ],
        require => User['vagrant'],
    }

    # Primary group for modern wikitech accounts
    sudo::group { 'wikidev_vagrant':
        privileges => [
            'ALL = (vagrant) NOPASSWD: ALL',
        ],
        group => 'wikidev',
        require => User['vagrant'],
    }

    # Primary group for users imported from old svn credentials
    # Bug: 63028
    sudo::group { 'svn_vagrant':
        privileges => [
            'ALL = (vagrant) NOPASSWD: ALL',
        ],
        group => 'svn',
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

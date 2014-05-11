# == labs_vagrant
#
# Configure a labs host to use MediaWiki-Vagrant to manage local wikis
#
# $inital_roles:  list of roles to include in labs vagrant before its first provision.
#
class labs_vagrant(
    $initial_roles = ['labs_initial_content']
) {

    file { '/home/vagrant':
        ensure     => 'directory',
    }

    sudo_user { 'vagrant' :
        privileges => [
            'ALL=(ALL) NOPASSWD:ALL',
        ],
    }

    # Primary group for modern wikitech accounts
    sudo_group { 'wikidev_vagrant':
        privileges => [
            'ALL = (vagrant) NOPASSWD: ALL',
        ],
        group => 'wikidev',
    }

    # Primary group for users imported from old svn credentials
    # Bug: 63028
    sudo_group { 'svn_vagrant':
        privileges => [
            'ALL = (vagrant) NOPASSWD: ALL',
        ],
        group => 'svn',
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
        require => Exec['git_clone_vagrant'],
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

    file { '/vagrant/puppet/manifests/manifests.d/vagrant-managed.pp':
        ensure  => present,
        replace => false,
        content => template('labs_vagrant/vagrant-managed.pp.erb'),
        owner   => 'vagrant',
        require => Exec['git_clone_vagrant'],
    }
}

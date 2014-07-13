# = Class: labs_vagrant
#
# Configure a labs host to use MediaWiki-Vagrant to manage local wikis
#
# == Parameters:
# - $install_directory: Directory to install MediaWiki-Vagrant in.
#   Default /srv/vagrant
# - $inital_roles: list of roles to include in labs vagrant before its first
#   provision. Default ['labs_initial_content']
#
class labs_vagrant(
    $install_directory = '/srv/vagrant',
    $initial_roles     = ['labs_initial_content'],
) {

    $legacy_directory = '/mnt/vagrant'

    if $install_directory != $legacy_directory {
        exec { 'migrate legacy files':
            command => template('labs_vagrant/migrate_legacy.erb'),
            onlyif  => "test -f ${legacy_directory}",
            before  => Git::Clone['vagrant'],
        }
    }

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
        directory => $install_directory,
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
    }

    file { $install_directory:
        recurse => true,
        owner   => 'vagrant',
        group   => 'www-data',
        require => Git::Clone['vagrant'],
    }

    file { '/vagrant':
        ensure  => 'link',
        target  => $install_directory,
        require => File[$install_directory],
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
        require => Git::Clone['vagrant'],
    }
}

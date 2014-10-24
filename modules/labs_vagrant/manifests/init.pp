# = Class: labs_vagrant
#
# Configure a labs host to use MediaWiki-Vagrant to manage local wikis
#
# == Parameters:
# - $install_directory: Directory to install MediaWiki-Vagrant in.
#   Default /srv/vagrant
#
class labs_vagrant(
    $install_directory = '/srv/vagrant',
) {

    $legacy_directory = '/mnt/vagrant'

    if $install_directory != $legacy_directory {
        exec { 'migrate legacy files':
            command => template('labs_vagrant/migrate_legacy.erb'),
            onlyif  => "/usr/bin/test -d ${legacy_directory}",
            before  => Git::Clone['vagrant'],
        }
    }

    file { '/home/vagrant':
        ensure => 'directory',
        owner  => 'vagrant',
        group  => 'vagrant',
    }

    sudo::user { 'vagrant' :
        privileges => [
            'ALL=(ALL) NOPASSWD: ALL',
        ],
    }

    sudo::group { 'wikidev_vagrant':
        privileges => [
            'ALL=(vagrant) NOPASSWD: ALL',
        ],
        group => 'wikidev',
    }

    git::clone { 'vagrant':
        directory => $install_directory,
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
        owner     => 'vagrant',
        group     => 'wikidev',
        shared    => true,
    }

    file { "${install_directory}/logs":
        ensure  => 'directory',
        owner   => 'vagrant',
        group   => 'www-data',
        mode    => '0775',
        require => Git::Clone['vagrant'],
    }

    file { '/vagrant':
        ensure  => 'link',
        target  => $install_directory,
        require => Git::Clone['vagrant'],
    }

    file { '/bin/labs-vagrant':
        ensure  => 'link',
        target  => '/vagrant/lib/labs-vagrant.rb',
        mode    => '0555',
        require => File['/vagrant'],
    }
}

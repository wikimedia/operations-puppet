# == Class: vagrant::mediawiki
#
# Provision MediaWiki-Vagrant
#
# === Parameters:
# [*install_directory*]
#   Directory where Vagrant stores global state.
#   (default: '/srv/vagrant-data')
#
class vagrant::mediawiki(
    $install_directory = '/srv/mediawiki-vagrant',
) {
    require ::vagrant::lxc

    package { 'nfs-kernel-server':
        ensure => present,
    }

    # Add custom apparmor profile that allows NFS mounts
    file { '/etc/apparmor.d/abstractions/lxc/container-base':
        ensure  => 'present',
        source  => 'puppet:///modules/vagrant/lxc/container-base',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['apparmor'],
    }

    git::clone { 'mediawiki/vagrant':
        directory => $install_directory,
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/vagrant',
        owner     => 'mwvagrant',
        group     => 'wikidev',
        shared    => true,
        require   => User['mwvagrant'],
    }

    exec { 'mediawiki_vagrant_setup':
        command     => "${install_directory}/setup.sh --silent",
        # The first call to vagrant will fail if the plugin isn't installed at
        # all. The second call will exit with an error if the plugin is
        # installed but out of date.
        unless      => '/usr/bin/vagrant plugin list | /bin/grep -q mediawiki-vagrant && /usr/bin/vagrant config --list',
        cwd         => $install_directory,
        user        => 'mwvagrant',
        environment => [
            "VAGRANT_HOME=${::vagrant::vagrant_home}",
        ],
        require     => Git::Clone['mediawiki/vagrant'],
    }

    # Create a local.yaml unless one already exists. This allows the user to
    # modify the defaults and add additional settings as needed without
    # fighting with Puppet over the contents of the file.
    file { "${install_directory}/puppet/hieradata/local.yaml":
        ensure  => 'present',
        source  => 'puppet:///modules/vagrant/hieradata/local.yaml',
        owner   => 'mwvagrant',
        group   => 'wikidev',
        mode    => '0664',
        replace => false,
        require => Git::Clone['mediawiki/vagrant'],
    }
}

# install the private key needed to contact newly-installed servers
#  to set up the initial puppet run.
# This key is dangerous, do not deploy widely!
# Also install a convenience script to ssh in using this key
class profile::access_new_install {
    file { '/root/.ssh/new_install':
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('ssh/new_install/new_install'),
        show_diff => false,
    }
    file { '/root/.ssh/new_install.pub':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => secret('ssh/new_install/new_install.pub'),
    }
    file { '/usr/local/bin/install-console':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/role/access_new_install/install-console',
    }
    file { '/usr/local/bin/install_console':
        ensure => 'link',
        target => '/usr/local/bin/install-console',
    }
}

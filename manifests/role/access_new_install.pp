# install the private key needed to contact newly-installed servers
#  to set up the initial puppet run.
# This key is dangerous, do not deploy widely!
class role::access_new_install {
    file { '/root/.ssh/new_install':
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///private/ssh/new_install/new_install',
    }
    file { '/root/.ssh/new_install.pub':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///private/ssh/new_install/new_install.pub',
    }
}

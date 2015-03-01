# == Class: vagrant::lxc
#
# Provision LXC for use as a Vagrant container
#
class vagrant::lxc {
    require ::vagrant
    require ::lxc

    exec { 'install_vagrant_lxc':
        command     => '/usr/bin/vagrant plugin install vagrant-lxc',
        unless      => '/usr/bin/vagrant plugin list | /bin/grep vagrant-lxc',
        user        => 'vagrant',
        environment => "VAGRANT_HOME=${::vagrant::vagrant_home}",
        require     => [ Package['lxc'], Package['build-essential'] ],
    }

    exec { 'vagrant_lcx_sudoers':
        command     => "/usr/bin/vagrant lxc sudoers --user vagrant",
        creates     => '/usr/local/bin/vagrant-lxc-wrapper',
        environment => "VAGRANT_HOME=${::vagrant::vagrant_home}",
        require     => Exec['install_vagrant_lxc'],
    }
}

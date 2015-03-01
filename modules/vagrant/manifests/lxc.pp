# == Class: vagrant::lxc
#
# Provision LXC for use as a Vagrant container
#
class vagrant::lxc {
    require ::vagrant
    require ::lxc

    exec { 'install_vagrant_lxc':
        command     => '/usr/bin/vagrant plugin install vagrant-lxc',
        unless      => '/usr/bin/vagrant plugin list | /bin/grep -q vagrant-lxc',
        user        => 'vagrant',
        environment => "VAGRANT_HOME=${::vagrant::vagrant_home}",
        require     => [ Package['lxc'], Package['build-essential'] ],
    }

    # Make sure that the plugin wrapper script is NOT installed
    file { '/usr/local/bin/vagrant-lxc-wrapper':
        ensure  => 'absent',
        require => Exec['install_vagrant_lxc'],
    }

    # Allow sudo for common vagrant lxc commands
    # See https://github.com/fgrehm/vagrant-lxc/blob/master/lib/vagrant-lxc/command/sudoers.rb
    sudo::user { 'vagrant-lxc':
        user       => 'vagrant',
        privileges => [
            # Container config file
            'ALL=(root) NOPASSWD: /bin/cat /var/lib/lxc/*/config',
            # Shared folders
            'ALL=(root) NOPASSWD: /bin/mkdir -p /var/lib/lxc/*/rootfs/*',
            'ALL=(root) NOPASSWD: /bin/sed -r -e * -ibak /etc/exports',
            'ALL=(root) NOPASSWD: /usr/bin/tee -a /etc/exports',
            'ALL=(root) NOPASSWD: /usr/sbin/exportfs -ar',
            # Container config customizations and pruning
            'ALL=(root) NOPASSWD: /bin/cp -f /tmp/lxc-config* /var/lib/lxc/*/config',
            'ALL=(root) NOPASSWD: /bin/chown root\:root /var/lib/lxc/*/config*',
            # Template import
            "ALL=(root) NOPASSWD: /bin/cp ${::vagrant::vagrant_home}/gems/gems/vagrant-lxc*/scripts/lxc-template /usr/share/lxc/templates/*",
            'ALL=(root) NOPASSWD: /bin/chmod +x /usr/share/lxc/templates/*',
            # Template removal
            'ALL=(root) NOPASSWD: /bin/rm /usr/share/lxc/templates/*',
            # Private network script and commands
            'ALL=(root) NOPASSWD: /sbin/ip addr add */24 dev *',
            'ALL=(root) NOPASSWD: /sbin/ifconfig * down',
            'ALL=(root) NOPASSWD: /sbin/brctl delbr *',
            "ALL=(root) NOPASSWD: ${::vagrant::vagrant_home}/gems/gems/vagrant-lxc*/scripts/pipework *",
            # Driver commands
            'ALL=(root) NOPASSWD: /usr/bin/which lxc-*',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-attach --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-attach -h',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-config lxc.lxcpath',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-create --version',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-create -B * --template * --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-destroy --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-info --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-ls',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-shutdown --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-start -d --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-stop --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-version',
            # Cleanup tmp files
            'ALL=(root) NOPASSWD: /bin/rm -rf /var/lib/lxc/*/rootfs/tmp/*',
        ],
    }
}

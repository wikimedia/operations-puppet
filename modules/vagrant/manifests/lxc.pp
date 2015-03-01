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

    # Allow paswordless sudo for common vagrant lxc commands
    # See https://github.com/fgrehm/vagrant-lxc/blob/master/lib/vagrant-lxc/command/sudoers.rb
    sudo::user { 'vagrant-lxc':
        user       => 'vagrant',
        privileges => [
            # Container config file
            'ALL=(root) NOPASSWD: /bin/cat /var/lib/lxc/*',
            # Shared folders
            'ALL=(root) NOPASSWD: /bin/mkdir -p /var/lib/lxc/*',
            # Container config customizations and pruning
            'ALL=(root) NOPASSWD: /bin/cp -f /tmp/* /var/lib/lxc/*',
            'ALL=(root) NOPASSWD: /bin/chown root\:root /var/lib/lxc/*',
            # Template import
            'ALL=(root) NOPASSWD: /bin/cp * /usr/*/lxc/templates/*',
            'ALL=(root) NOPASSWD: /bin/chmod +x /usr/*/lxc/templates/*',
            # Template removal
            'ALL=(root) NOPASSWD: /bin/rm /usr/*/lxc/templates/*',
            # Packaging
            'ALL=(root) NOPASSWD: /bin/tar --numeric-owner -cvzf /tmp/*/rootfs.tar.gz -C /var/lib/lxc/* ./rootfs',
            'ALL=(root) NOPASSWD: /bin/chown *\:* /tmp/*/rootfs.tar.gz',
            # Private network script and commands
            'ALL=(root) NOPASSWD: /sbin/ip addr add */24 dev *',
            'ALL=(root) NOPASSWD: /sbin/ifconfig * down',
            'ALL=(root) NOPASSWD: /sbin/brctl delbr *',
            "ALL=(root) NOPASSWD: ${::vagrant::vagrant_home}/gems/gems/vagrant-lxc*/scripts/pipework *",
            # Driver commands
            'ALL=(root) NOPASSWD: /usr/bin/lxc-version',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-ls',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-info --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-create -B * --template * --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-create --version',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-destroy --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-start -d --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-stop --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-shutdown --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-attach --name *',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-attach -h',
            'ALL=(root) NOPASSWD: /usr/bin/lxc-config lxc.lxcpath',
            # Cleanup tmp files
            'ALL=(root) NOPASSWD: /bin/rm -rf /var/lib/lxc/*/rootfs/tmp/*',
        ],
    }
}

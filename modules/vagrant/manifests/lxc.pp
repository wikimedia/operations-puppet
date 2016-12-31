# == Class: vagrant::lxc
#
# Provision LXC for use as a Vagrant container.
#
# WARNING: For use only in the Labs environment. Installation of the
# vagrant-lxc plugin is done by fetching ruby gems over the internet.
#
class vagrant::lxc {
    require ::vagrant
    require ::lxc

    require_package('build-essential')
    require_package('ruby1.9.1-dev')

    ::vagrant::plugin { 'vagrant-lxc':
        ensure  => present,
        require => [
            Package['build-essential'],
            Package['ruby1.9.1-dev'],
        ],
    }

    # Make sure that the plugin wrapper script is NOT installed
    file { '/usr/local/bin/vagrant-lxc-wrapper':
        ensure  => 'absent',
        require => Vagrant::Plugin['vagrant-lxc'],
    }

    # Allow sudo for common vagrant lxc commands instead of using the plugin's
    # kind of scary sudo proxy ruby script.
    # See https://github.com/fgrehm/vagrant-lxc/blob/master/lib/vagrant-lxc/command/sudoers.rb
    sudo::user { 'vagrant-lxc':
        user       => 'mwvagrant',
        privileges => [
            ## vagrant-lxc < 2.1.0
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
            # NFS
            'ALL=(root) NOPASSWD: /etc/init.d/nfs-kernel-server *',
            'ALL=(root) NOPASSWD: /bin/sed -r -e * -ibak /tmp/exports',
            'ALL=(root) NOPASSWD: /bin/cp /tmp/exports /etc/exports',

            ## vagrant-lxc >= 2.1.0 (uses /usr/bin/env)
            # Container config file
            'ALL=(root) NOPASSWD: /usr/bin/env cat /var/lib/lxc/*/config',
            # Shared folders
            'ALL=(root) NOPASSWD: /usr/bin/env mkdir -p /var/lib/lxc/*/rootfs/*',
            'ALL=(root) NOPASSWD: /usr/bin/env sed -r -e * -ibak /etc/exports',
            'ALL=(root) NOPASSWD: /usr/bin/env tee -a /etc/exports',
            'ALL=(root) NOPASSWD: /usr/bin/env exportfs -ar',
            # Container config customizations and pruning
            'ALL=(root) NOPASSWD: /usr/bin/env cp -f /tmp/lxc-config* /var/lib/lxc/*/config',
            'ALL=(root) NOPASSWD: /usr/bin/env chown root\:root /var/lib/lxc/*/config*',
            # Template import
            "ALL=(root) NOPASSWD: /usr/bin/env cp ${::vagrant::vagrant_home}/gems/gems/vagrant-lxc*/scripts/lxc-template /usr/share/lxc/templates/*",
            'ALL=(root) NOPASSWD: /usr/bin/env chmod +x /usr/share/lxc/templates/*',
            # Template removal
            'ALL=(root) NOPASSWD: /usr/bin/env rm /usr/share/lxc/templates/*',
            # Private network script and commands
            'ALL=(root) NOPASSWD: /usr/bin/env ip addr add */24 dev *',
            'ALL=(root) NOPASSWD: /usr/bin/env ifconfig * down',
            'ALL=(root) NOPASSWD: /usr/bin/env brctl delbr *',
            "ALL=(root) NOPASSWD: /usr/bin/env ${::vagrant::vagrant_home}/gems/gems/vagrant-lxc*/scripts/pipework *",
            # Driver commands
            'ALL=(root) NOPASSWD: /usr/bin/env which lxc-*',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-attach --name *',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-attach -h',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-config lxc.lxcpath',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-create --version',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-create -B * --template * --name *',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-destroy --name *',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-info --name *',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-ls',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-shutdown --name *',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-start -d --name *',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-stop --name *',
            'ALL=(root) NOPASSWD: /usr/bin/env lxc-version',
            # Cleanup tmp files
            'ALL=(root) NOPASSWD: /usr/bin/env rm -rf /var/lib/lxc/*/rootfs/tmp/*',
            # NFS
            'ALL=(root) NOPASSWD: /usr/bin/env /etc/init.d/nfs-kernel-server *',
            'ALL=(root) NOPASSWD: /usr/bin/env sed -r -e * -ibak /tmp/exports',
            'ALL=(root) NOPASSWD: /usr/bin/env cp /tmp/exports /etc/exports',

            # Vagrant 1.9.1
            # NFS
            'ALL=(root) NOPASSWD: /bin/chown 0\:0 /tmp/vagrant*',
            'ALL=(root) NOPASSWD: /bin/mv -f /tmp/vagrant* /etc/exports',
        ],
    }
}

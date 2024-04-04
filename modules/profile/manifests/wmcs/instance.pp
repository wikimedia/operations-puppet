# basic profile for every CloudVPS instance
class profile::wmcs::instance(
    Boolean             $mount_nfs                     = lookup('mount_nfs',                     {default_value => false}),
    Array[Stdlib::Fqdn] $metricsinfra_prometheus_nodes = lookup('metricsinfra_prometheus_nodes', {default_value => []}),
) {
    # a VM without isc-dhcp-client can be considered broken
    ensure_packages(['isc-dhcp-client'])

    # cloud-init is installed on base cloud images, but
    #  ensuring it here may prevent it from being accidentally
    #  removed, e.g. as part of a weird dependency behavior
    #  in T361749
    ensure_packages(['cloud-init'])

    if ! defined(Class['Sudo']) {
        class { 'sudo': }
    }

    sudo::group { 'ops':
        privileges => ['ALL=(ALL) NOPASSWD: ALL'],
    }

    file { '/etc/sudoers.d/T205463-disable-sudo-password-prompts':
        ensure       => 'present',
        owner        => 'root',
        group        => 'root',
        mode         => '0440',
        content      => "Defaults passwd_tries=0,lecture=\"never\"\n",
        validate_cmd => '/usr/sbin/visudo -cqf %',
        require      => Class['sudo'],
    }

    class { 'profile::ldap::client::labs': }

    # TODO: remove after a full puppet cycle
    file { [ '/var/log/syslog', '/var/log/messages', ]:
        mode => '0640',
    }

    file { '/etc/wmcs-instancename':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::hostname}\n",
    }
    file { '/etc/wmcs-project':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::wmcs_project}\n",
    }

    if debian::codename::le('bullseye') {
        file { '/etc/wmflabs-project':
            ensure => link,
            target => '/etc/wmcs-project',
        }

        file { '/etc/wmflabs-instancename':
            ensure => link,
            target => '/etc/wmcs-instancename',
        }

        # wmflabs_imageversion is provided by labs_vmbuilder/files/postinst.copy
        # because this is a pre-installed file, migrating is nontrivial, so we keep
        # the original file name.
        file { '/etc/wmcs-imageversion':
            ensure => link,
            target => '/etc/wmflabs_imageversion',
        }
    }

    file { '/etc/mailname':
        ensure  => present,
        content => "${::fqdn}\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    package { 'puppet-lint':
        ensure => present,
    }

    # We are using nfsv4, which doesn't require rpcbind on clients. T241710
    # However, removing the package removes nfs-common.
    if $facts['nfscommon_version'] {
        service { 'rpcbind':
            ensure => 'stopped',
        }
        exec { 'systemctl mask rpcbind.service':
            path    => ['/bin', '/usr/bin'],
            creates => '/etc/systemd/system/rpcbind.service',
        }
    }

    # Allows per-host placement of NFS mounts, defaults to false
    if $mount_nfs {
        require profile::wmcs::nfsclient
    }

    # In production, we try to be punctilious about having Puppet manage
    # system state, and thus it's reasonable to purge Apache site configs
    # that have not been declared via Puppet. But on Labs we want to allow
    # users to manage configuration files locally if they so choose,
    # without having Puppet clobber them. So provision a
    # /etc/apache2/sites-local directory for Apache to recurse into during
    # initialization, but do not manage its contents.
    exec { 'enable_sites_local':
        command => '/bin/mkdir -m0755 /etc/apache2/sites-local && \
                    /usr/bin/touch /etc/apache2/sites-local/dummy.conf && \
                    /bin/echo "Include sites-local/*" >> /etc/apache2/apache2.conf',
        onlyif  => '/usr/bin/test -e /etc/apache2/apache2.conf -a ! -d /etc/apache2/sites-local',
    }

    # Uninstall Diamond from remaining Buster servers where it was enabled
    # at some point,
    if debian::codename::le('buster') {
        class { 'diamond': }

        profile::auto_restarts::service { 'diamond':
            ensure => absent,
        }
    }

    class { 'prometheus::node_ssh_open_sessions': }

    # TODO: move this so it doesn't need a lint:ignore for a lookup in the middle of a class
    lookup('classes', {default_value => []}).include()  # lint:ignore:wmf_styleguide

    # Signal to rc.local that this VM is up and we don't need to run the firstboot
    #  script anymore
    file { '/root/firstboot_done':
        ensure  => present,
        content => '',
    }

    # Update /etc/hosts using the new cloud-init template.
    #  Note that cloud-init will only update the file if
    #  manage_etc_hosts = True in the initial cloud setup
    #  of the VM. That means that legacy VMs (from before
    #  widespread adoption of cloud-init) will not
    #  be affected by this.
    #
    # We might also be on a system that doesn't have cloud-init
    #  at all, which is just fine.
    exec { 'cloud-init refresh /etc/hosts':
        command     => '/usr/bin/cloud-init single -n cc_update_etc_hosts',
        onlyif      => '/usr/bin/test -f /usr/bin/cloud-init',
        refreshonly => true,
    }

    file { ['/etc/cloud', '/etc/cloud/templates']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/cloud/templates/hosts.debian.tmpl':
        ensure  => present,
        content => template('profile/wmcs/instance/hosts.debian.tmpl.erb'),
        owner   => 'root',
        group   => 'root',
        require => File['/etc/cloud', '/etc/cloud/templates'],
        notify  => Exec['cloud-init refresh /etc/hosts'],
        mode    => '0644',
    }

    # sudo rules added by cloud-init for the 'debian' user, not needed in our setup
    file { [ '/etc/sudoers.d/90-cloud-init-users', '/etc/sudoers.d/debian-cloud-init' ]:
        ensure => absent,
    }

    # this seems to be installed by default but doesn't do much on a VM.
    #  T287309
    package { 'smartmontools':
        ensure => absent,
        notify => Exec['reset-failed for smartmontools'],
    }
    exec { 'reset-failed for smartmontools':
        path        => ['/bin', '/usr/bin'],
        command     => 'systemctl reset-failed smartd.service',
        refreshonly => true,
    }

    class {'::cinderutils': }

    if !empty($metricsinfra_prometheus_nodes) {
        ferm::rule { 'metricsinfra-prometheus-all':
            rule => "saddr @resolve((${metricsinfra_prometheus_nodes.join(' ')})) ACCEPT;"
        }
    }
}

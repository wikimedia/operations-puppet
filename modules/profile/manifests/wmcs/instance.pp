# basic profile for every CloudVPS instance
class profile::wmcs::instance(
    Boolean                                               $mount_nfs                     = lookup('mount_nfs',                     {default_value => false}),
    Array[Stdlib::Host]                                   $metricsinfra_prometheus_nodes = lookup('metricsinfra_prometheus_nodes', {default_value => []}),
    Hash[String[1], Variant[String[1], Array[String[1]]]] $root_extra_keys               = lookup('passwords::root::extra_keys',   {default_value => {}}),
) {
    if debian::codename::eq('bullseye') {
        ensure_packages(['isc-dhcp-client'])
    }

    # cloud-init is installed on base cloud images, but
    #  ensuring it here may prevent it from being accidentally
    #  removed, e.g. as part of a weird dependency behavior
    #  in T361749
    ensure_packages(['cloud-init'])

    if ! defined(Class['Sudo']) {
        class { 'sudo': }
    }

    $module_path = get_module_path($module_name)
    $root_keys_data = loadyaml("${module_path}/data/wmcs/instance/root-keys.yaml")
    $root_keys = wmflib::deep_merge(
        $root_keys_data['keys'],
        Hash($root_extra_keys.map |$username, $keys| { [$username, [$keys].flatten] }),
    )

    ssh::userkey { 'root':
        ensure  => present,
        content => template('profile/wmcs/instance/root-authorized-keys.erb'),
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

    file { '/etc/wmcs-instancename':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::facts['networking']['hostname']}\n",
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
        content => "${::facts['networking']['fqdn']}\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
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
        firewall::service { 'metricsinfra-prometheus-all-tcp':
            proto      => 'tcp',
            port_range => [1, 65535],
            srange     => $metricsinfra_prometheus_nodes,
        }
        firewall::service { 'metricsinfra-prometheus-all-udp':
            proto      => 'udp',
            port_range => [1, 65535],
            srange     => $metricsinfra_prometheus_nodes,
        }
    }

    if debian::codename::ge('bookworm') {
        # Prevent systemd-networkd from tearing down our primary
        #  network interface if there's a delay in RTM_NEWROUTE requests.
        #  This will only take proper effect on Trixie and later but the
        #  unit may get upgraded on Bookworm in the future.
        #  On remaining bullseye hosts we don't have networkd installed at
        #  all so this will do nothing at all but should be harmless.
        #
        # See https://github.com/systemd/systemd/issues/25441
        #
        service { 'systemd-networkd': }
        systemd::override { 'SYSTEMD_NETLINK_DEFAULT_TIMEOUT':
            unit    => 'systemd-networkd',
            source  => 'puppet:///modules/profile/wmcs/instance/netlink_default_timeout.conf',
            restart => true,
        }
    }

    # Work around the above issue on bookworm by constantly monitoring
    #  whether or not the network has gone down.
    file {'/usr/local/sbin/check_and_restart_networkd':
        ensure => stdlib::ensure(debian::codename::eq('bookworm'), 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
        source => 'puppet:///modules/profile/wmcs/instance/check_and_restart_networkd.sh',
    }
    systemd::timer::job { 'restart_networkd_on_network_failure':
        ensure          => stdlib::ensure(debian::codename::eq('bookworm')),
        description     => 'Restart systemd-networkd if no routes are found',
        command         => '/usr/local/sbin/check_and_restart_networkd',
        interval        => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:*:00',
        },
        logging_enabled => true,
        user            => 'root',
    }

    # Permit DHCPv6 response traffic on hosts with host-level firewall - T392611
    firewall::service { 'dhcp6-response':
        proto  => 'udp',
        port   => 546,
        # TODO: filter on the source port as well? not currently supported by any of our wrappers
        # sport => 547,
        srange => ['fe80::/10'],
        drange => ['fe80::/10'],
    }
}

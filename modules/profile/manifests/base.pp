class profile::base(
    $puppetmaster  = hiera('puppetmaster'),
    $dns_alt_names = hiera('profile::base::dns_alt_names', false),
    # TODO/puppet4: revert to using "undef"
    $environment   = hiera('profile::base::environment', ''),
    $use_apt_proxy = hiera('profile::base::use_apt_proxy', true),
    $purge_apt_sources = hiera('profile::base::purge_apt_sources', false),
    $domain_search = hiera('profile::base::domain_search', $::domain), # lint:ignore:wmf_styleguide
    $nameservers   = hiera('profile::base::nameservers', $::nameservers), # lint:ignore:wmf_styleguide
    $remote_syslog = hiera('profile::base::remote_syslog', ['syslog.eqiad.wmnet', 'syslog.codfw.wmnet']),
    $remote_syslog_tls = hiera('profile::base::remote_syslog_tls', []),
    $enable_rsyslog_exporter = hiera('profile::base::enable_rsyslog_exporter', false),
    Enum['critical', 'disabled', 'enabled'] $notifications = hiera('profile::base::notifications', 'enabled'),
    $monitor_systemd = hiera('profile::base::monitor_systemd', true),
    $core_dump_pattern = hiera('profile::base::core_dump_pattern', '/var/tmp/core/core.%h.%e.%p.%t'),
    $ssh_server_settings = hiera('profile::base::ssh_server_settings', {}),
    $nrpe_allowed_hosts = hiera('profile::base::nrpe_allowed_hosts', undef),
    $group_contact = hiera('contactgroups', 'admins'),
    $check_disk_options = hiera('profile::base::check_disk_options', '-w 6% -c 3% -W 6% -K 3% -l -e -A -i "/srv/sd[a-b][1-3]" -i "/srv/nvme[0-9]n[0-9]p[0-9]" --exclude-type=tracefs'),
    $check_disk_critical = hiera('profile::base::check_disk_critical', false),
    # TODO/puppet4: revert to using "undef"
    $check_raid_policy = hiera('profile::base::check_raid_policy', ''),
    $check_raid_interval = hiera('profile::base::check_raid_interval', 10),
    $check_raid_retry = hiera('profile::base::check_raid_retry', 10),
    $check_smart = hiera('profile::base::check_smart', true),
    $overlayfs = hiera('profile::base::overlayfs', false),
    # We have included a default here as this seems to be the convention even though 
    # it contradicts https://wikitech.wikimedia.org/wiki/Puppet_coding
    # TODO: need to clarify with _joe_ when he comes back of vacation 2019-03-11
    $debdeploy_exclude_mounts = hiera('profile::base::debdeploy::exclude_mounts', []),
) {
    require ::profile::base::certificates
    class { '::apt':
        use_proxy     => $use_apt_proxy,
        purge_sources => $purge_apt_sources,
    }

    file { ['/usr/local/sbin', '/usr/local/share/bash']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class { '::base::puppet':
        server        => $puppetmaster,
        dns_alt_names => $dns_alt_names,
        environment   => $environment,
    }

    # Temporary workaround for T140100. Remove as soon as Labs instances get
    # grub-pc or trusty gets phased out from Labs, whichever comes first.
    if ($::realm == 'production') or (os_version('debian >= jessie')) {
        class { '::grub::defaults':
        }
    }

    include ::passwords::root
    include ::network::constants

    class { '::base::resolving':
        domain_search => $domain_search,
        nameservers   => $nameservers,
    }

    class { '::rsyslog': }
    if $enable_rsyslog_exporter and os_version('debian >= jessie') {
        include ::profile::prometheus::rsyslog_exporter
    }

    unless empty($remote_syslog) and empty($remote_syslog_tls) {
        class { '::base::remote_syslog':
            enable            => true,
            central_hosts     => $remote_syslog,
            central_hosts_tls => $remote_syslog_tls,
        }
    }

    #TODO: make base::sysctl a profile itself?
    class { '::base::sysctl': }
    class { '::motd': }
    class { '::base::standard_packages': }
    class { '::base::environment':
        core_dump_pattern => $core_dump_pattern,
    }

    class { '::base::phaste': }
    class { '::base::screenconfig': }

    class { '::ssh::client': }

    # Ssh server default settings are good for most installs, but some overrides
    # might be needed

    create_resources('class', {'ssh::server' => $ssh_server_settings})

    if $nrpe_allowed_hosts != undef {
        $allowed_nrpe_hosts = $nrpe_allowed_hosts
    } else {
        $allowed_nrpe_hosts = join($network::constants::special_hosts[$realm]['monitoring_hosts'], ',')
    }

    class { '::nrpe':
        allowed_hosts => $allowed_nrpe_hosts,
    }

    class { '::base::kernel':
        overlayfs        => $overlayfs,
    }

    if ($facts['is_virtual'] == false and $::processor0 !~ /AMD/) {
        class { 'prometheus::node_intel_microcode': }
    }

    class { '::base::debdeploy':
      exclude_mounts => $debdeploy_exclude_mounts,
    }

    if $facts['has_ipmi'] {
        class { '::ipmi::monitor': }
    }

    if os_version('debian >= jessie') {
        class { '::base::initramfs': }
        class { '::base::auto_restarts': }
    }

    $notifications_enabled = $notifications ? {
        'disabled' => '0',
        default    => '1',
    }

    class { '::base::monitoring::host':
        contact_group            => $group_contact,
        nrpe_check_disk_options  => $check_disk_options,
        nrpe_check_disk_critical => $check_disk_critical,
        raid_write_cache_policy  => $check_raid_policy,
        # for 'forking' checks (i.e. all but mdadm, which essentially just reads
        # kernel memory from /proc/mdstat) check every $check_raid_interval
        # minutes instead of default of one minute. If the check is non-OK, retry
        # every $check_raid_retry
        raid_check_interval      => $check_raid_interval,
        raid_retry_interval      => $check_raid_retry,
        notifications_enabled    => $notifications_enabled,
        is_critical              => ($notifications == 'critical'),
        monitor_systemd          => $monitor_systemd,
    }

    if os_version('ubuntu == trusty') {
        # This should be identical to the packaged config, with the addition
        #  of 'copytruncate'.  copytruncate isn't great,  but without it
        #  we wind up with a lot of .1 logfiles that grow without bound and
        #  are ignored by logrotate, e.g. prometheus-node-exporter.log.1
        #
        # Also somewhat related:
        #
        #    https://bugs.launchpad.net/ubuntu/+source/upstart/+bug/1350782
        logrotate::rule { 'upstart':
            ensure        => present,
            file_glob     => '/var/log/upstart/*.log',
            frequency     => 'daily',
            missing_ok    => true,
            rotate        => 7,
            compress      => true,
            not_if_empty  => true,
            no_create     => true,
            copy_truncate => true,
        }
    }

    if $check_smart and $facts['is_virtual'] == false {
        class { '::smart': }
    }
}

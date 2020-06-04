class profile::base(
    Boolean $use_apt_proxy = lookup('profile::base::use_apt_proxy'),
    Boolean $purge_apt_sources = lookup('profile::base::purge_apt_sources'),
    Boolean $purge_apt_preferences = lookup('profile::base::purge_apt_preferences'),
    Boolean $manage_apt_source = lookup('profile::base::manage_apt_source'),
    String  $mirror_server = lookup('profile::base::mirror_server'),
    $domain_search = hiera('profile::base::domain_search', $::domain), # lint:ignore:wmf_styleguide
    $nameservers   = hiera('profile::base::nameservers', $::nameservers), # lint:ignore:wmf_styleguide
    $remote_syslog = hiera('profile::base::remote_syslog', []),
    $remote_syslog_tls = hiera('profile::base::remote_syslog_tls', []),
    $enable_kafka_shipping = hiera('profile::base::enable_kafka_shipping', true),
    Enum['critical', 'disabled', 'enabled'] $notifications = hiera('profile::base::notifications', 'enabled'),
    $monitor_systemd = hiera('profile::base::monitor_systemd', true),
    Boolean $monitor_screens = lookup('monitor_screens', {default_value => true}),
    $core_dump_pattern = hiera('profile::base::core_dump_pattern', '/var/tmp/core/core.%h.%e.%p.%t'),
    $ssh_server_settings = hiera('profile::base::ssh_server_settings', {}),
    $group_contact = hiera('contactgroups', 'admins'),
    String $mgmt_group_contact = lookup('mgmt_contactgroups', {default_value => 'admins'}),
    $check_disk_options = hiera('profile::base::check_disk_options', '-w 6% -c 3% -W 6% -K 3% -l -e -A -i "/srv/sd[a-b][1-3]" -i "/srv/nvme[0-9]n[0-9]p[0-9]" --exclude-type=fuse.fuse_dfs --exclude-type=tracefs'),
    $check_disk_critical = hiera('profile::base::check_disk_critical', false),
    # TODO/puppet4: revert to using "undef"
    $check_raid_policy = hiera('profile::base::check_raid_policy', ''),
    $check_raid_interval = hiera('profile::base::check_raid_interval', 10),
    $check_raid_retry = hiera('profile::base::check_raid_retry', 10),
    Boolean $check_raid = lookup('profile::base::check_raid', {default_value => true}),
    $check_smart = hiera('profile::base::check_smart', true),
    $overlayfs = hiera('profile::base::overlayfs', false),
    # We have included a default here as this seems to be the convention even though 
    # it contradicts https://wikitech.wikimedia.org/wiki/Puppet_coding
    # TODO: need to clarify with _joe_ when he comes back of vacation 2019-03-11
    $debdeploy_exclude_mounts = lookup('profile::base::debdeploy::exclude_mounts'),
    $debdeploy_exclude_filesystems = lookup('profile::base::debdeploy::exclude_filesystems'),
    $debdeploy_filter_services = lookup('profile::base::debdeploy::filter_services', Hash, 'hash', {}),
    $monitoring_hosts = hiera('monitoring_hosts', []),
    Hash $wikimedia_clusters = lookup('wikimedia_clusters'),
    String $cluster = lookup('cluster'),
    Wmflib::Ensure $hardware_monitoring = lookup('profile::base::hardware_monitoring', {'default_value' => 'present'}),
    String $legacy_cloud_search_domain = lookup('profile::base::legacy_cloud_search_domain', {'default_value' => ''}),
) {
    # Sanity checks for cluster - T234232
    if ! has_key($wikimedia_clusters, $cluster) {
        fail("Cluster ${cluster} not defined in wikimedia_clusters")
    }

    if ! has_key($wikimedia_clusters[$cluster]['sites'], $::site) {
        fail("Site ${::site} not found in cluster ${cluster}")
    }

    contain profile::base::puppet
    require profile::base::certificates
    # Ensure we update the CA certificates before managing any services
    Exec['update-ca-certificates'] -> Service<| |>
    class { 'apt':
        use_proxy         => $use_apt_proxy,
        purge_sources     => $purge_apt_sources,
        purge_preferences => $purge_apt_preferences,
        manage_apt_source => $manage_apt_source,
        mirror            => $mirror_server,
    }

    file { ['/usr/local/sbin', '/usr/local/share/bash']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class {'adduser': }

    class { 'grub::defaults': }

    include passwords::root
    include network::constants

    class { 'base::resolving':
        domain_search              => $domain_search,
        nameservers                => $nameservers,
        legacy_cloud_search_domain => $legacy_cloud_search_domain,
    }

    class { 'rsyslog': }
    include profile::prometheus::rsyslog_exporter

    class {'profile::rsyslog::kafka_shipper':
        enable => $enable_kafka_shipping,
    }

    unless empty($remote_syslog) and empty($remote_syslog_tls) {
        class { 'base::remote_syslog':
            enable            => true,
            central_hosts     => $remote_syslog,
            central_hosts_tls => $remote_syslog_tls,
        }
    }

    #TODO: make base::sysctl a profile itself?
    class { 'base::sysctl': }
    class { 'motd': }
    class { 'base::standard_packages': }
    git::systemconfig { 'protocol_v2':
        settings => {
            'protocol' => {
                'version' => '2',
            }
        }
    }
    if debian::codename::le('buster') {
        class { 'toil::acct_handle_wtmp_not_rotated': }
    }
    class { 'base::environment':
        core_dump_pattern => $core_dump_pattern,
    }

    class { 'base::phaste': }
    class { 'base::screenconfig': }

    class { 'ssh::client': }

    # Ssh server default settings are good for most installs, but some overrides
    # might be needed

    create_resources('class', {'ssh::server' => $ssh_server_settings})

    class { 'nrpe':
        allowed_hosts => join($monitoring_hosts, ','),
    }

    class { 'base::kernel':
        overlayfs => $overlayfs,
    }

    class { 'base::debdeploy':
      exclude_mounts      => $debdeploy_exclude_mounts,
      exclude_filesystems => $debdeploy_exclude_filesystems,
      filter_services     => $debdeploy_filter_services,
    }

    if $facts['has_ipmi'] {
        class { 'ipmi::monitor':
            ensure => $hardware_monitoring
        }
    }

    class { 'base::initramfs': }
    class { 'base::auto_restarts': }

    $notifications_enabled = $notifications ? {
        'disabled' => '0',
        default    => '1',
    }

    class { 'base::monitoring::host':
        contact_group            => $group_contact,
        mgmt_contact_group       => $mgmt_group_contact,
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
        monitor_screens          => $monitor_screens,
        puppet_interval          => $profile::base::puppet::interval,
        raid_check               => $check_raid,
        hardware_monitoring      => $hardware_monitoring
    }

    if $facts['is_virtual'] and debian::codename::le('buster') {
            class {'haveged': }
    } elsif !$facts['is_virtual'] {
        include profile::prometheus::nic_saturation_exporter
        class { 'prometheus::node_nic_firmware': }
        if $check_smart {
            class { '::smart': }
        }
        if $::processor0 !~ /AMD/ {
            class { 'prometheus::node_intel_microcode': }
        }
    }
    # This is responsible for ~75%+ of all recdns queries...
    # https://phabricator.wikimedia.org/T239862
    host { 'statsd.eqiad.wmnet':
        ip           => '10.64.16.149', # graphite1004
        host_aliases => 'statsd',
    }
}

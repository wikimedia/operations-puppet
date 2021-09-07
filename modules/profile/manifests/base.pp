class profile::base(
    Variant[Stdlib::Fqdn, Array[Stdlib::Fqdn]] $domain_search = lookup('profile::base::domain_search', {default_value => $::domain}),
    Array[Stdlib::Host] $nameservers = lookup('profile::base::nameservers', {default_value => $::nameservers}),
    Array $remote_syslog = lookup('profile::base::remote_syslog', {default_value => []}),
    Array $remote_syslog_tls = lookup('profile::base::remote_syslog_tls', {default_value => []}),
    Boolean $enable_kafka_shipping = lookup('profile::base::enable_kafka_shipping', {default_value => true}),
    Enum['critical', 'disabled', 'enabled'] $notifications = lookup('profile::base::notifications',  {default_value => 'enabled'}),
    Boolean $monitor_systemd = lookup('profile::base::monitor_systemd', {default_value => true}),
    Boolean $monitor_screens = lookup('monitor_screens', {default_value => true}),
    String $core_dump_pattern = lookup('profile::base::core_dump_pattern', {default_value => '/var/tmp/core/core.%h.%e.%p.%t'}),
    Hash $ssh_server_settings = lookup('profile::base::ssh_server_settings', {default_value => {}}),
    String $group_contact = lookup('contactgroups',  {default_value => 'admins'}),
    String $mgmt_group_contact = lookup('mgmt_contactgroups', {default_value => 'admins'}),
    String $check_disk_options = lookup('profile::base::check_disk_options', {default_value => '-w 6% -c 3% -W 6% -K 3% -l -e -A -i "/srv/sd[a-b][1-3]" -i "/srv/nvme[0-9]n[0-9]p[0-9]" --exclude-type=fuse.fuse_dfs --exclude-type=tracefs'}),
    Boolean $check_disk_critical = lookup('profile::base::check_disk_critical', {default_value => false}),
    String $check_raid_policy = lookup('profile::base::check_raid_policy', {default_value => ''}),
    Integer $check_raid_interval = lookup('profile::base::check_raid_interval', {default_value => 10}),
    Integer $check_raid_retry = lookup('profile::base::check_raid_retry', {default_value => 10}),
    Boolean $check_raid = lookup('profile::base::check_raid', {default_value => true}),
    Boolean $check_smart = lookup('profile::base::check_smart', {default_value => true}),
    Boolean $overlayfs = lookup('profile::base::overlayfs', {default_value => false}),
    Array[Stdlib::Host] $monitoring_hosts = lookup('monitoring_hosts', {default_value => []}),
    Hash $wikimedia_clusters = lookup('wikimedia_clusters'),
    String $cluster = lookup('cluster'),
    Wmflib::Ensure $hardware_monitoring = lookup('profile::base::hardware_monitoring', {'default_value' => 'present'}),
    String $legacy_cloud_search_domain = lookup('profile::base::legacy_cloud_search_domain', {'default_value' => ''}),
    Boolean $enable_contacts = lookup('profile::base::enable_contacts')
) {
    # Sanity checks for cluster - T234232
    if ! has_key($wikimedia_clusters, $cluster) {
        fail("Cluster ${cluster} not defined in wikimedia_clusters")
    }

    if ! has_key($wikimedia_clusters[$cluster]['sites'], $::site) {
        fail("Site ${::site} not found in cluster ${cluster}")
    }

    contain profile::base::puppet
    contain profile::base::certificates
    include profile::pki::client
    if $enable_contacts {
        include profile::contacts
    }
    include profile::base::netbase
    include profile::logoutd
    include profile::apt

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

    include profile::debdeploy::client

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

    class { 'prometheus::node_debian_version': }

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

    include profile::emacs
}

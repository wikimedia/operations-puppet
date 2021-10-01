class profile::base(
    Array $remote_syslog = lookup('profile::base::remote_syslog', {default_value => []}),
    Array $remote_syslog_tls = lookup('profile::base::remote_syslog_tls', {default_value => []}),
    Boolean $enable_kafka_shipping = lookup('profile::base::enable_kafka_shipping', {default_value => true}),
    String $core_dump_pattern = lookup('profile::base::core_dump_pattern', {default_value => '/var/tmp/core/core.%h.%e.%p.%t'}),
    Hash $ssh_server_settings = lookup('profile::base::ssh_server_settings', {default_value => {}}),
    Boolean $check_smart = lookup('profile::base::check_smart', {default_value => true}),
    Boolean $overlayfs = lookup('profile::base::overlayfs', {default_value => false}),
    Array[Stdlib::Host] $monitoring_hosts = lookup('monitoring_hosts', {default_value => []}),
    Hash $wikimedia_clusters = lookup('wikimedia_clusters'),
    String $cluster = lookup('cluster'),
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

    include profile::resolving

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

    class { 'base::initramfs': }
    class { 'base::auto_restarts': }

    include profile::monitoring

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

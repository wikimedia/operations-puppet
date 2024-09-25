# = Class: profile::icinga
#
# Sets up a icinga instance which checks services
# and hosts for Wikimedia Production cluster
#
# = Parameters
#
class profile::icinga(
    Hash[String, Hash]            $monitoring_groups     = lookup('monitoring::groups'),
    Hash[String, String]          $ldap_config           = lookup('ldap', {'merge' => 'hash'}),
    String                        $active_host           = lookup('profile::icinga::active_host'),
    Array[Stdlib::Host]           $partners              = lookup('profile::icinga::partners'),
    Enum['stopped', 'running']    $ensure_service        = lookup('profile::icinga::ensure_service'),
    String                        $virtual_host          = lookup('profile::icinga::virtual_host'),
    String                        $icinga_user           = lookup('profile::icinga::icinga_user'),
    String                        $icinga_group          = lookup('profile::icinga::icinga_group'),
    Stdlib::Unixpath              $retention_file        = lookup('profile::icinga::retention_file'),
    Integer                       $max_concurrent_checks = lookup('profile::icinga::max_concurrent_checks'),
    Stdlib::Unixpath              $check_result_path     = lookup('profile::icinga::check_result_path'),
    Stdlib::Unixpath              $temp_path             = lookup('profile::icinga::temp_path'),
    Stdlib::Unixpath              $temp_file             = lookup('profile::icinga::temp_file'),
    Stdlib::Unixpath              $status_file           = lookup('profile::icinga::status_file'),
    String                        $apache2_htpasswd_salt = lookup('profile::icinga::apache2_htpasswd_salt'),
    Hash[String, String]          $apache2_auth_users    = lookup('profile::icinga::apache2_auth_users'),
    Wmflib::Ensure                $ircbot_ensure         = lookup('profile::icinga::ircbot::ensure'),
    Array[String]                 $datacenters           = lookup('datacenters'),
    Hash[String, Hash]            $atlas_measurements    = lookup('ripeatlas_measurements'),
    Wmflib::Infra::Devices        $infra_devices         = lookup('infra_devices'),
    Integer[1]                    $logs_keep_days        = lookup('profile::icinga::logs_keep_days'),
    Hash[String, String]          $mgmt_parents          = lookup('profile::icinga::mgmt_parents'),
    Boolean                       $stub_contactgroups    = lookup('profile::icinga::stub_contactgroups', {'default_value' => false}),
    Integer                       $shard_size_warning    = lookup('profile::elasticsearch::monitor::shard_size_warning', {'default_value' => 110}),
    Integer                       $shard_size_critical   = lookup('profile::elasticsearch::monitor::shard_size_critical', {'default_value' => 140}),
    String                        $threshold             = lookup('profile::elasticsearch::monitor::threshold', {'default_value' => '>=0.2'}),
    Integer                       $timeout               = lookup('profile::elasticsearch::monitor::timeout', {'default_value' => 4}),
    Hash                          $wikimedia_clusters    = lookup('wikimedia_clusters'),
){
    $is_passive = !($::fqdn == $active_host)

    ensure_packages('mariadb-client')

    # leaving address blank means also using IPv6
    class { 'rsync::server':
        address => '',
    }

    class { 'netops::monitoring':
        atlas_measurements => $atlas_measurements,
        infra_devices      => $infra_devices,
    }
    class { 'facilities':
        mgmt_parents => $mgmt_parents
    }

    class { 'icinga::nsca::daemon':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { 'icinga::monitor::toollabs': }
    class { 'icinga::monitor::cloudgw': }
    class { 'icinga::monitor::legal': }
    class { 'icinga::monitor::wikitech_static': }

    # monitoring of content on commons (T124812)
    prometheus::blackbox::check::http { 'commons.wikimedia.org':
        server_name        => 'commons.wikimedia.org',
        instance_label     => 'commons.wikimedia.org',
        # Not ideal but good enough, see task for more context https://phabricator.wikimedia.org/T312840
        ip4                => ipresolve("text-lb.${::site}.wikimedia.org", 4),
        ip6                => ipresolve("text-lb.${::site}.wikimedia.org", 6),
        path               => '/wiki/Main_Page',
        body_regex_matches => ['Picture of the day'],
        severity           => 'page',
    }

    class { 'icinga::monitor::elasticsearch::cirrus_cluster_checks':
        shard_size_warning  => $shard_size_warning,
        shard_size_critical => $shard_size_critical,
        timeout             => $timeout,
        threshold           => $threshold,
    }

    # Experimental load-balancer monitoring for cloudelastic service using service-checker
    # This was isolated from lvs::monitor_services as cloudelastic use case deviates from
    # the usual use case. see T229621
    class { 'icinga::monitor::cloudelastic': }

    class { 'icinga::monitor::librenms': }
    class { 'icinga::monitor::debmonitor': }
    class { 'icinga::monitor::gitlab': }

    class { 'icinga::event_handlers::raid':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { 'profile::bird::anycast_monitoring': }
    class { 'profile::prometheus::alerts': }

    class { 'profile::prometheus::icinga_exporter': }

    # Check that the public eventstreams endpoint's recentchange stream has data.
    # See also: T215013. (The default params use the public endpoint.)
    class { 'profile::eventstreams::monitoring': }

    class { 'icinga::monitor::etcd_mw_config':
        icinga_user => $icinga_user,
    }


    class { 'snmp::mibs': }

    $wikimedia_clusters.each |String $cluster_name, Hash $cluster_config| {
        $cluster_config['sites'].keys.each |String $cluster_site| {
            monitoring::group { "${cluster_name}_${cluster_site}":
                description => "Hosts for cluster ${cluster_name} in ${cluster_site}"
            }
        }
    }

    create_resources(monitoring::group, $monitoring_groups)

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${virtual_host}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Icinga',
    }

    $ircbot_present = ($is_passive or $ircbot_ensure == 'absent') ? {
        false => 'present', #aka active
        true  => 'absent',
    }
    $enable_notifications = $is_passive ? {
        false => 1, #aka active
        true  => 0,
    }
    $enable_event_handlers = $is_passive ? {
        false => 1, #aka active
        true  => 0,
    }

    class { 'icinga':
        enable_notifications  => $enable_notifications,
        enable_event_handlers => $enable_event_handlers,
        ensure_service        => $ensure_service,
        icinga_user           => $icinga_user,
        icinga_group          => $icinga_group,
        max_concurrent_checks => $max_concurrent_checks,
        retention_file        => $retention_file,
        logs_keep_days        => $logs_keep_days,
        stub_contactgroups    => $stub_contactgroups,
    }

    class { 'sslcert::dhparam': }
    class { 'icinga::web':
        icinga_user           => $icinga_user,
        icinga_group          => $icinga_group,
        apache2_htpasswd_salt => $apache2_htpasswd_salt,
        apache2_auth_users    => $apache2_auth_users,
    }
    profile::idp::client::httpd::site { $virtual_host:
        vhost_content   => 'profile/idp/client/httpd-icinga.erb',
        acme_chief_cert => 'icinga',
        document_root   => '/usr/share/icinga/htdocs',
        protected_uri   => '/icinga',
        cookie_scope    => '/',
        required_groups => [
            "cn=wmf,${ldap_config['groups_cn']},${ldap_config['base-dn']}",
            "cn=nda,${ldap_config['groups_cn']},${ldap_config['base-dn']}",
        ]
    }


    include profile::icinga::external_monitoring

    class { 'icinga::naggen':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { 'profile::icinga::ircbot':
        ensure => $ircbot_present,
    }

    if ($is_passive) {

        file { '/etc/icinga/active_host':
          ensure  => present,
          owner   => 'root',
          group   => 'root',
          mode    => '0444',
          content => $active_host,
        }

        file { '/usr/local/sbin/sync_icinga_state':
          ensure => present,
          owner  => 'root',
          group  => 'root',
          mode   => '0755',
          source => 'puppet:///modules/profile/icinga/sync_icinga_state.sh',
        }

        profile::auto_restarts::service { 'apache2': }

    }

    $all_icinga_hosts = $partners + $active_host

    rsync::server::module { 'icinga-tmpfs':
        read_only     => 'yes',
        path          => '/var/icinga-tmpfs',
        auto_firewall => true,
        hosts_allow   => $all_icinga_hosts
    }

    rsync::server::module { 'icinga-cache':
        read_only     => 'yes',
        path          => '/var/cache/icinga',
        auto_firewall => true,
        hosts_allow   => $all_icinga_hosts
    }

    rsync::server::module { 'icinga-lib':
        read_only     => 'yes',
        path          => '/var/lib/icinga',
        auto_firewall => true,
        hosts_allow   => $all_icinga_hosts
    }

    # access to the web interface
    firewall::service { 'icinga-https':
        proto => 'tcp',
        port  => 443,
    }

    firewall::service { 'icinga-http':
        proto => 'tcp',
        port  => 80,
    }

    # allow NSCA (Nagios Service Check Acceptor)
    # connections on port 5667/tcp
    firewall::service { 'icinga-nsca':
        proto    => 'tcp',
        port     => 5667,
        src_sets => ['DOMAIN_NETWORKS', 'FRACK_NETWORKS'],
    }

    # We absent the timer job on active hosts, should only exist on passive ones
    $timer_job_presence = $is_passive ? {
        true  => 'present',
        false => 'absent',
    }

    systemd::timer::job { 'sync-icinga-state':
        ensure      => $timer_job_presence,
        description => 'Regular jobs to sync icinga state between hosts',
        user        => 'root',
        command     => "/usr/bin/systemd-cat -t 'sync_icinga_state' /usr/local/sbin/run-no-puppet /usr/local/sbin/sync_icinga_state",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:33:00'},
    }

    # On the passive host, replace the downtime script with a warning.
    $absent_script = @("SCRIPT")
    #!/bin/sh
    echo 'This is not the active Icinga host. Please go to ${active_host} instead.'
    exit 127
    | SCRIPT
    $downtime_script = $is_passive ? {
        true  => $absent_script,
        false => file('profile/icinga/icinga-downtime.sh'),
    }

    # script to schedule host/service downtimes
    file { '/usr/local/bin/icinga-downtime':
        ensure  => present,
        content => $downtime_script,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
    }

    # On the passive host, display a warning in the MOTD.
    $motd_presence = $is_passive ? {
        true  => 'present',
        false => 'absent',
    }

    motd::script { 'inactive_warning':
        ensure   => $motd_presence,
        priority => 1,
        content  => template('profile/icinga/inactive.motd.erb'),
    }

    $metamonitor_home = '/var/lib/metamonitor'
    user { 'metamonitor':
        ensure     => present,
        system     => true,
        home       => $metamonitor_home,
        managehome => true,
        shell      => '/bin/bash',
        groups     => $icinga_group,
    }

    file { "${metamonitor_home}/.ssh":
        ensure => directory,
        owner  => 'metamonitor',
        group  => 'metamonitor',
        mode   => '0700',
    }

    file { "${metamonitor_home}/.ssh/known_hosts":
        ensure => present,
        source => 'puppet:///modules/profile/icinga/metamonitor_known_hosts',
        owner  => 'metamonitor',
        group  => 'metamonitor',
        mode   => '0644',
    }

    ::keyholder::agent { 'metamonitor':
        trusted_groups => ['metamonitor'],
    }

    profile::auto_restarts::service { 'keyholder-proxy': }

    systemd::timer::job { 'sync_check_icinga_contacts':
        ensure          => present,
        description     => 'Automatically sync the Icinga contacts to the metamonitoring host',
        command         => '/usr/local/bin/sync-check-icinga-contacts',
        interval        => {
            'start'    => 'OnCalendar',
            # Daily splayed by hostname at minute 19.
            # Depending on fqdn_rand seed there's the risk of not splaying
            # evenly throught the day.
            'interval' => "*-*-* ${sprintf('%02d', fqdn_rand(24, 1))}:19:00",
        },
        logging_enabled => false,
        user            => 'metamonitor',
        require         => File['/usr/local/bin/sync-check-icinga-contacts'],
    }
}

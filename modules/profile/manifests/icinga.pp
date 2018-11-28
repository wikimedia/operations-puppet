# = Class: profile::icinga
#
# Sets up a icinga instance which checks services
# and hosts for Wikimedia Production cluster
#
# = Parameters
#
class profile::icinga(
    Hash[String, Hash] $monitoring_groups = hiera('monitoring::groups'),
    String $active_host = hiera('profile::icinga::active_host'),
    Array[String] $partners = hiera('profile::icinga::partners', []),
    Enum['stopped', 'running'] $ensure_service = hiera('profile::icinga::ensure_service', 'running'),
    String $virtual_host = hiera('profile::icinga::virtual_host'),
    String $icinga_user = hiera('profile::icinga::icinga_user', 'icinga'),
    String $icinga_group = hiera('profile::icinga::icinga_group', 'icinga'),
    Stdlib::Unixpath $retention_file = hiera('profile::icinga::retention_file', '/var/cache/icinga/retention.dat'),
    Integer $max_concurrent_checks = hiera('profile::icinga::max_concurrent_checks', 0),
    Stdlib::Unixpath $check_result_path = hiera('profile::icinga::check_result_path', '/var/icinga-tmpfs'),
    Stdlib::Unixpath $temp_path = hiera('profile::icinga::temp_path', '/var/icinga-tmpfs'),
    Stdlib::Unixpath $temp_file = hiera('profile::icinga::temp_file', '/var/icinga-tmpfs/icinga.tmp'),
    Stdlib::Unixpath $status_file = hiera('profile::icinga::status_file', '/var/icinga-tmpfs/status.dat'),
){
    $is_passive = !($::fqdn == $active_host)

    require_package('mariadb-client')

    # leaving address blank means also using IPv6
    class { 'rsync::server':
        address => '',
    }

    class { 'netops::monitoring': }
    class { 'facilities': }
    class { 'lvs::monitor': }
    class { 'icinga::monitor::checkpaging': }

    class { 'icinga::nsca::daemon':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { 'icinga::monitor::wikidata': }

    class { 'icinga::monitor::ores':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { 'icinga::monitor::toollabs': }
    class { 'icinga::monitor::legal': }
    class { 'icinga::monitor::certs': }
    class { 'icinga::monitor::gsb': }
    class { 'icinga::monitor::commons': }
    class { 'icinga::monitor::elasticsearch': }
    class { 'icinga::monitor::wdqs': }
    class { 'icinga::monitor::performance': }
    class { 'icinga::monitor::services': }
    class { 'icinga::monitor::reading_web': }
    class { 'icinga::monitor::traffic': }

    class { 'icinga::event_handlers::raid':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { '::profile::bird::anycast_monitoring': }
    class { '::profile::prometheus::alerts': }
    class { '::profile::maps::alerts': }
    class { '::profile::cache::kafka::alerts': }
    class { '::profile::prometheus::icinga_exporter': }

    class { '::icinga::monitor::etcd_mw_config':
        icinga_user => $icinga_user,
    }

    class { '::snmp::mibs': }

    create_resources(monitoring::group, $monitoring_groups)

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${virtual_host}",
    }

    $ircbot_present = $is_passive ? {
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

    class { '::icinga':
        enable_notifications  => $enable_notifications,
        enable_event_handlers => $enable_event_handlers,
        ensure_service        => $ensure_service,
        icinga_user           => $icinga_user,
        icinga_group          => $icinga_group,
        max_concurrent_checks => $max_concurrent_checks,
        retention_file        => $retention_file,
    }

    class { '::sslcert::dhparam': }
    class { '::icinga::web':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
        virtual_host => $virtual_host,
    }

    class { '::icinga::naggen':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { '::profile::icinga::ircbot':
        ensure => $ircbot_present,
    }

    if ($is_passive) {
        file { '/usr/local/sbin/sync_icinga_state':
          ensure  => present,
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          content => template('role/icinga/sync_icinga_state.sh.erb'),
        }
    }
    else {
        $partners.each |String $partner| {
            ferm::service { "icinga-rsync-${partner}":
              proto  => 'tcp',
              port   => 873,
              srange => "(@resolve(${partner}) @resolve(${partner}, AAAA))",
            }
        }
    }

    # allow NSCA (Nagios Service Check Acceptor)
    # connections on port 5667/tcp
    ferm::service { 'icinga-nsca':
        proto  => 'tcp',
        port   => '5667',
        srange => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
    }

    rsync::server::module { 'icinga-tmpfs':
        read_only   => 'yes',
        path        => '/var/icinga-tmpfs',
        hosts_allow => $partners
    }
    rsync::server::module { 'icinga-cache':
        read_only   => 'yes',
        path        => '/var/cache/icinga',
        hosts_allow => $partners
    }
    rsync::server::module { 'icinga-lib':
        read_only   => 'yes',
        path        => '/var/lib/icinga',
        hosts_allow => $partners
    }

    # We absent the cron on active hosts, should only exist on passive ones
    $cron_presence = $is_passive ? {
        true  => 'present',
        false => 'absent',
    }

    cron { 'sync-icinga-state':
        ensure  => $cron_presence,
        minute  => '33',
        command => '/usr/local/sbin/run-no-puppet /usr/local/sbin/sync_icinga_state >/dev/null 2>&1',
    }

    # On the passive host, replace the downtime script with a warning.
    $downtime_script = $is_passive ? {
        true  => 'icinga-downtime-absent.sh',
        false => 'icinga-downtime.sh',
    }

    # script to schedule host/service downtimes
    file { '/usr/local/bin/icinga-downtime':
        ensure  => present,
        content => template("profile/icinga/${downtime_script}.erb"),
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
}

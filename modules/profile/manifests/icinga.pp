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
    String $icinga_user = hiera('profile::icinga::icinga_user', 'nagios'),
    String $icinga_group = hiera('profile::icinga::icinga_group', 'nagios'),
    Stdlib::Unixpath $retention_file = hiera('profile::icinga::retention_file', '/var/lib/icinga/retention.dat'),
    Integer $max_concurrent_checks = hiera('profile::icinga::max_concurrent_checks', 0),
    Stdlib::Unixpath $check_result_path = hiera('profile::icinga::check_result_path', '/var/icinga-tmpfs'),
    Stdlib::Unixpath $temp_path = hiera('profile::icinga::temp_path', '/var/icinga-tmpfs'),
    Stdlib::Unixpath $temp_file = hiera('profile::icinga::temp_file', '/var/icinga-tmpfs/icinga.tmp'),
    Stdlib::Unixpath $status_file = hiera('profile::icinga::status_file', '/var/icinga-tmpfs/status.dat'),
    String $apache2_htpasswd_salt = hiera('profile::icinga::apache2_htpasswd_salt', ''),
    Hash[String, String] $apache2_auth_users = hiera('profile::icinga::apache2_auth_users', {}),
    Hash $ldap_config = lookup('ldap', Hash, hash, {}),
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
    class { 'icinga::monitor::commons': }

    class { 'icinga::monitor::elasticsearch::cirrus_cluster_checks': }

    class { 'icinga::monitor::wdqs': }
    class { 'icinga::monitor::performance': }
    class { 'icinga::monitor::services': }
    class { 'icinga::monitor::reading_web': }
    class { 'icinga::monitor::traffic': }
    class { 'icinga::monitor::gerrit': }

    # check planet for cert expiration and regular content updates
    # warn/crit = hours before content is considered stale
    class { 'icinga::monitor::planet':
        url  => 'https://en.planet.wikimedia.org/',
        warn => 24,
        crit => 48,
    }

    class { 'icinga::event_handlers::raid':
        icinga_user  => $icinga_user,
        icinga_group => $icinga_group,
    }

    class { '::profile::bird::anycast_monitoring': }
    class { '::profile::prometheus::alerts': }
    class { '::profile::maps::alerts': }
    class { '::profile::cache::kafka::alerts': }
    class { '::profile::prometheus::icinga_exporter': }

    # Check that the public eventstreams endpoint's recentchange stream has data.
    # See also: T215013. (The default params use the public endpoint.)
    class { '::profile::eventstreams::monitoring': }

    class { '::icinga::monitor::etcd_mw_config':
        icinga_user => $icinga_user,
    }


    class { '::snmp::mibs': }

    create_resources(monitoring::group, $monitoring_groups)

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => "check_ssl_http_letsencrypt!${virtual_host}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Icinga',
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
        icinga_user           => $icinga_user,
        icinga_group          => $icinga_group,
        virtual_host          => $virtual_host,
        apache2_htpasswd_salt => $apache2_htpasswd_salt,
        apache2_auth_users    => $apache2_auth_users,
        ldap_server           => $ldap_config['ro-server'],
        ldap_server_fallback  => $ldap_config['ro-server-fallback'],
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

        base::service_auto_restart { 'apache2': }

    }

    # In order to do failovers, we need to be able to rsync state
    # from any one to any other, whether or not Puppet has run any subset
    # of the hosts.
    $all_icinga_hosts = $partners + $active_host

    $all_icinga_hosts.each |String $partner| {
        ferm::service { "icinga-rsync-${partner}":
            proto  => 'tcp',
            port   => 873,
            srange => "(@resolve(${partner}) @resolve(${partner}, AAAA))",
        }
    }

    rsync::server::module { 'icinga-tmpfs':
        read_only   => 'yes',
        path        => '/var/icinga-tmpfs',
        hosts_allow => $all_icinga_hosts
    }
    rsync::server::module { 'icinga-cache':
        read_only   => 'yes',
        path        => '/var/cache/icinga',
        hosts_allow => $all_icinga_hosts
    }
    rsync::server::module { 'icinga-lib':
        read_only   => 'yes',
        path        => '/var/lib/icinga',
        hosts_allow => $all_icinga_hosts
    }

    # allow NSCA (Nagios Service Check Acceptor)
    # connections on port 5667/tcp
    ferm::service { 'icinga-nsca':
        proto  => 'tcp',
        port   => '5667',
        srange => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
    }

    # We absent the cron on active hosts, should only exist on passive ones
    $cron_presence = $is_passive ? {
        true  => 'present',
        false => 'absent',
    }

    cron { 'sync-icinga-state':
        ensure  => $cron_presence,
        minute  => '33',
        command => "/usr/bin/systemd-cat -t 'sync_icinga_state' /usr/local/sbin/run-no-puppet /usr/local/sbin/sync_icinga_state",
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

    $metamonitor_home = '/var/lib/metamonitor'
    user { 'metamonitor':
        ensure => present,
        system => true,
        home   => $metamonitor_home,
        shell  => '/bin/bash',
        groups => $icinga_group,
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

}

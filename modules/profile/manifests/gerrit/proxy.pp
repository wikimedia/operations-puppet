# sets up a TLS proxy for Gerrit
class profile::gerrit::proxy(
    Stdlib::IP::Address::V4           $ipv4                 = lookup('profile::gerrit::ipv4'),
    Optional[Stdlib::IP::Address::V6] $ipv6                 = lookup('profile::gerrit::ipv6'),
    Stdlib::Fqdn                      $host                 = lookup('profile::gerrit::host'),
    Stdlib::Fqdn                      $active_host          = lookup('profile::gerrit::active_host'),
    Boolean                           $use_acmechief        = lookup('profile::gerrit::use_acmechief'),
    Optional[Array[Stdlib::Fqdn]]     $replica_hosts        = lookup('profile::gerrit::replica_hosts'),
    Stdlib::Fqdn                      $replica_host         = lookup('profile::gerrit::replica_host'),
    Optional[Array[Stdlib::Fqdn]]     $spare_hosts          = lookup('profile::gerrit::spare_hosts'),
    Stdlib::Fqdn                      $spare_host           = lookup('profile::gerrit::spare_host'),
    Boolean                           $enable_monitoring    = lookup('profile::gerrit::enable_monitoring'),
    Integer                           $max_connections      = lookup('profile::gerrit::proxy::max_connections'),
    Boolean                           $log_only             = lookup('profile::gerrit::proxy::log_only', { 'default_value' => false }),
    Stdlib::Unixpath                  $gerrit_site          = lookup('profile::gerrit::gerrit_site'),
) {

    include network::constants
    $is_replica = $facts['fqdn'] == $replica_host
    $is_spare = $facts['fqdn'] == $spare_host

    if $is_replica {
        $tls_host = $replica_hosts[0]
    } elsif $is_spare {
        $tls_host = $spare_hosts[0]
    } else {
        $tls_host = $host
    }
    if debian::codename::eq('bookworm') {
        apt::pin { 'libapache2-mod-qos-backport':
            package  => 'libapache2-mod-qos',
            pin      => 'release n=bookworm-backports',
            priority => 1002,
        }
    }
    if debian::codename::eq('bookworm') {
        apt::package_from_bpo { 'libapache2-mod-qos':
            distro => 'bookworm',
        }
    } else {
        ensure_packages(['libapache2-mod-qos'])
    }
    if $enable_monitoring {
        monitoring::service { 'https':
            description    => 'HTTPS',
            check_command  => "check_ssl_on_host_port_letsencrypt!${tls_host}!${tls_host}!443",
            contact_group  => 'admins,gerrit',
            notes_url      => 'https://phabricator.wikimedia.org/project/view/330/',
            migration_task => 'T384922',
        }

        if !($is_replica or $is_spare) {
            prometheus::blackbox::check::http { 'gerrit-tls':
                server_name        => $tls_host,
                team               => 'collaboration-services-releng',
                severity           => 'critical',
                path               => '/',
                follow_redirects   => true,
                status_matches     => [200,302],
                ip_families        => ['ip4','ip6'],
                port               => 443,
                force_tls          => true,
                body_regex_matches => ['Gerrit Code Review'],
            }
        }
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    class { 'httpd':
        modules             => ['rewrite', 'headers', 'proxy', 'proxy_http', 'remoteip', 'ssl', 'qos', 'setenvif'],
        wait_network_online => true,
        require             => Package['libapache2-mod-qos'],
    }

    file { '/var/www':
        ensure  => directory,
        require => Class['httpd'],
    }

    httpd::conf { 'qos':
        content => template('profile/gerrit/proxy/qos.conf.erb'),
        require => Package['libapache2-mod-qos'],
    }

    httpd::site { $tls_host:
        content => template('profile/gerrit/apache.erb'),
        require => Httpd::Conf['qos'],
    }

    file { '/var/www/robots.txt':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/gerrit/robots.txt'
    }

    # Error page stuff
    file { '/var/www/error.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('gerrit/error.html.erb'),
    }
    file { '/var/www/page-bkg.cache.jpg':
        ensure => link,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => "${gerrit_site}/static/page-bkg.cache.jpg",
    }
    file { '/var/www/wikimedia-codereview-logo.cache.png':
        ensure => link,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => "${gerrit_site}/static/wikimedia-codereview-logo.cache.png",
    }
    gerrit::proxy::set { 'production-hosts':
        ensure => present,
        hosts  => $network::constants::production_networks,
    }
    gerrit::proxy::set { 'cloud-hosts':
        ensure => present,
        hosts  => $network::constants::cloud_networks,
    }
    file { [
            '/etc/mtail/httpd_access_mod_qos-mtail.mtail',
            '/etc/mtail/httpd_error_mod_qos-mtail.mtail',
        ]:
            ensure => 'absent',
    }
    mtail::program { 'httpd_mod_qos':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/httpd_mod_qos.mtail',
    }
}

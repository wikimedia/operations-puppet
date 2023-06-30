# sets up a TLS proxy for Gerrit
class profile::gerrit::proxy(
    Stdlib::IP::Address::V4           $ipv4              = lookup('profile::gerrit::ipv4'),
    Optional[Stdlib::IP::Address::V6] $ipv6              = lookup('profile::gerrit::ipv6'),
    Stdlib::Fqdn                      $host              = lookup('profile::gerrit::host'),
    String                            $daemon_user       = lookup('profile::gerrit::daemon_user'),
    Boolean                           $is_replica        = lookup('profile::gerrit::is_replica'),
    Boolean                           $use_acmechief     = lookup('profile::gerrit::use_acmechief'),
    Optional[Array[Stdlib::Fqdn]]     $replica_hosts     = lookup('profile::gerrit::replica_hosts'),
    Boolean                           $enable_monitoring = lookup('profile::gerrit::enable_monitoring'),
) {

    $gerrit_site = "/var/lib/${daemon_user}/review_site"

    if $is_replica {
        $tls_host = $replica_hosts[0]
    } else {
        $tls_host = $host
    }

    if $enable_monitoring {
        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => "check_ssl_on_host_port_letsencrypt!${tls_host}!${tls_host}!443",
            contact_group => 'admins,gerrit',
            notes_url     => 'https://phabricator.wikimedia.org/project/view/330/',
        }

        if !$is_replica {
            prometheus::blackbox::check::http { 'gerrit-tls':
                server_name        => $tls_host,
                team               => 'serviceops-collab-releng',
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
        modules             => ['rewrite', 'headers', 'proxy', 'proxy_http', 'remoteip', 'ssl'],
        wait_network_online => true,
    }

    httpd::site { $tls_host:
        content => template('profile/gerrit/apache.erb'),
    }

    $robots = ['User-Agent: *', 'Disallow: /g', 'Disallow: /r/plugins/gitiles', 'Crawl-delay: 1']
    file { '/var/www/robots.txt':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => inline_template("<%= @robots.join('\n') %>"),
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
        source => "${gerrit_site}/static/wikimedia-codereview-logo.cache.png",
    }
}

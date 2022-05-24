# sets up a TLS proxy for Gerrit
class gerrit::proxy(
    Stdlib::IP::Address::V4 $ipv4,
    Stdlib::Fqdn $host                           = $::gerrit::host,
    Boolean $replica                             = false,
    Boolean $maint_mode                          = false,
    Boolean $use_acmechief                       = false,
    Optional[Array[Stdlib::Fqdn]] $replica_hosts = $::gerrit::replica_hosts,
    Boolean $enable_monitoring                   = true,
    Optional[Stdlib::IP::Address::V6] $ipv6      = undef,
) {

    require gerrit::jetty
    if $replica {
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
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    # lint:ignore:wmf_styleguide
    # TODO: this whole class should be a profile
    class { 'httpd':
        remove_default_ports => true,
        modules              => ['rewrite', 'headers', 'proxy', 'proxy_http', 'remoteip', 'ssl'],

    }
    # lint:endignore

    httpd::site { $tls_host:
        content => template('gerrit/apache.erb'),
    }

    # Let apache only listen on the service IP
    httpd::conf{ 'gerrit_listen_service_ip':
        ensure   => present,
        priority => 0,
        content  => template('gerrit/apache.ports.conf.erb')
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
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => '/var/lib/gerrit2/review_site/static/page-bkg.cache.jpg',
    }
    file { '/var/www/wikimedia-codereview-logo.cache.png':
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => '/var/lib/gerrit2/review_site/static/wikimedia-codereview-logo.cache.png',
    }
}

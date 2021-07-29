class profile::mediawiki::webserver(
    Boolean $has_lvs = lookup('has_lvs'),
    Boolean $has_tls = lookup('profile::mediawiki::webserver::has_tls'),
    Boolean $stream_to_logstash = lookup('profile::mediawiki::webserver::stream_to_logstash', {'default_value' => false}),
    Optional[Stdlib::Port::User] $fcgi_port = lookup('profile::php_fpm::fcgi_port', {'default_value' => undef}),
    String $fcgi_pool = lookup('profile::mediawiki::fcgi_pool', {'default_value' => 'www'}),
    Mediawiki::Vhost_feature_flags $vhost_feature_flags = lookup('profile::mediawiki::vhost_feature_flags', {'default_value' => {}}),
    Array[String] $prometheus_nodes = lookup('prometheus_nodes'),
    # Sites shared between different installations
    Array[Mediawiki::SiteCollection] $common_sites = lookup('mediawiki::common_sites'),
    # Installation/site dependent sites
    Array[Mediawiki::SiteCollection] $sites = lookup('mediawiki::sites')
) {
    include ::profile::mediawiki::httpd
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)

    # Declare the proxies explicitly with retry=0
    httpd::conf { 'fcgi_proxies':
        ensure  => present,
        content => template('mediawiki/apache/fcgi_proxies.conf.erb')
    }

    # we need fonts!
    class { '::mediawiki::packages::fonts': }

    # Set feature flags for all mediawiki::web::vhost resources
    Mediawiki::Web::Vhost {
        php_fpm_fcgi_endpoint => $fcgi_proxy,
        feature_flags         => $vhost_feature_flags,
    }

    # Define all websites for apache, as the sum of general and env-specific stuff.
    class { '::mediawiki::web::sites':
        siteconfigs => $common_sites + $sites,
        fcgi_proxy  => $fcgi_proxy,
    }

    if $has_lvs {
        require ::profile::lvs::realserver

        class { 'conftool::scripts': }
        conftool::credentials { 'mwdeploy':
            home => '/var/lib/mwdeploy',
        }

        # Will re-enable a mediawiki appserver after running scap pull
        file { '/usr/local/bin/mw-pool':
            ensure => present,
            source => 'puppet:///modules/mediawiki/mw-pool',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }

        monitoring::service { 'etcd_mw_config':
            ensure        => present,
            description   => 'MediaWiki EtcdConfig up-to-date',
            check_command => "check_etcd_mw_config_lastindex!${::site}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Etcd',
        }
    }

    ferm::service { 'mediawiki-http':
        proto   => 'tcp',
        notrack => true,
        port    => 'http',
        srange  => '$DOMAIN_NETWORKS',
    }

    # If a service check happens to run while we are performing a
    # graceful restart of Apache, we want to try again before declaring
    # defeat. See T103008.
    monitoring::service { 'appserver http':
        description    => 'Apache HTTP',
        check_command  => 'check_http_wikipedia',
        retries        => 2,
        retry_interval => 2,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    }

    if $has_tls == true {
        # Override niceness to run at -19 like php-fpm
        file { '/etc/systemd/system/envoyproxy.service.d/niceness-override.conf':
            content => "[Service]\nNice=-19\nCPUAccounting=yes\n",
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Exec['systemd daemon-reload for envoyproxy.service']
        }
        include ::profile::tlsproxy::envoy
    }

    # Mtail program to gather latency metrics from application servers, see T226815
    class { '::mtail':
        logs  => ['/var/log/apache2/other_vhosts_access.log'],
        group => 'adm',
    }
    mtail::program { 'apache2-mediawiki':
        ensure => present,
        notify => undef,
        source => 'puppet:///modules/mtail/programs/mediawiki_access_log.mtail',
    }
    # Stream to logstash, we are using an if condition to avoid breaking beta T244472
    if  $stream_to_logstash {
        if defined('$::_role'){
            $server_role = regsubst($::_role.split('/')[-1], '_', '-', 'G')
        } else {
            $server_role = 'generic'
        }
        rsyslog::input::file { "${server_role}-mediawiki-apache2-access":
            path               => '/var/log/apache2/other_vhosts_access.log',
            reopen_on_truncate => 'on',
            addmetadata        => 'on',
            addceetag          => 'off',
            syslog_tag         => "${server_role}-mw-access",
        }
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    ferm::service { 'mtail':
        proto  => 'tcp',
        port   => '3903',
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }

}

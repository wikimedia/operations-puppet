class profile::mediawiki::webserver(
    Boolean $has_lvs = lookup('has_lvs'),
    Boolean $has_tls = lookup('profile::mediawiki::webserver::has_tls'),
    Boolean $stream_to_logstash = lookup('profile::mediawiki::webserver::stream_to_logstash', {'default_value' => false}),
    Optional[Stdlib::Port::User] $fcgi_port = lookup('profile::php_fpm::fcgi_port', {'default_value' => undef}),
    String $fcgi_pool = lookup('profile::mediawiki::fcgi_pool', {'default_value' => 'www'}),
    Array[Wmflib::Php_version] $php_versions = lookup('profile::mediawiki::php::php_versions', {'default_value' => ['7.2']}),
    Mediawiki::Vhost_feature_flags $vhost_feature_flags = lookup('profile::mediawiki::vhost_feature_flags', {'default_value' => {}}),
    # Sites shared between different installations
    Array[Mediawiki::SiteCollection] $common_sites = lookup('mediawiki::common_sites'),
    # Installation/site dependent sites
    Array[Mediawiki::SiteCollection] $sites = lookup('mediawiki::sites'),
    Boolean $install_fonts = lookup('profile::mediawiki::webserver::install_fonts', {'default_value' => false}),
) {
    include ::profile::mediawiki::httpd
    $versioned_port = php::fpm::versioned_port($fcgi_port, $php_versions)
    $fcgi_proxies = $php_versions.map |$idx, $version| {
        $fcgi_pool_name = $idx? {
            0 => $fcgi_pool,
            default => "${fcgi_pool}-${version}"
        }
        $default = ($idx == 0)
        $retval = [$version, mediawiki::fcgi_endpoint($versioned_port[$version], $fcgi_pool_name, $default)]
    }

    # Declare the proxies explicitly with retry=0
    httpd::conf { 'fcgi_proxies':
        ensure  => present,
        content => template('mediawiki/apache/fcgi_proxies.conf.erb')
    }

    # we may not need fonts anymore! (T294378)
    $font_ensure = $install_fonts.bool2str('installed','absent')
    class { '::mediawiki::packages::fonts':
        ensure => $font_ensure,
    }

    # Set feature flags for all mediawiki::web::vhost resources
    Mediawiki::Web::Vhost {
        php_fpm_fcgi_endpoint => $fcgi_proxies[0],
        feature_flags         => $vhost_feature_flags,
        additional_fcgi_endpoints => $fcgi_proxies[1, -1]
    }

    # Define all websites for apache, as the sum of general and env-specific stuff.
    # Note: "fcgi_proxy" is used in the additonal non-MediaWiki sites, and is
    # set to the default php engine.
    class { '::mediawiki::web::sites':
        siteconfigs => $common_sites + $sites,
        fcgi_proxy  => $fcgi_proxies[0][1],
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
}

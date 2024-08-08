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
    Optional[Wmflib::Php_version] $default_php_version = lookup('profile::mediawiki::webserver::default_php_version', {'default_value' => undef}),
) {
    include ::profile::mediawiki::httpd
    $versioned_port = php::fpm::versioned_port($fcgi_port, $php_versions)

    # The ordering of $fcgi_proxies determines the fallback php version in mediawiki::web::vhost
    # so we want to order php versions accordingly.
    $ordered_php_versions = $default_php_version ? {
        undef => $php_versions,
        default => [$default_php_version] + $php_versions.filter |$x| { $x != $default_php_version}
    }

    $fcgi_proxies = $ordered_php_versions.map |$version| {
        $retval = [$version, mediawiki::fcgi_endpoint($versioned_port[$version], "${fcgi_pool}-${version}")]
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
    }

    ferm::service { 'mediawiki-http':
        proto   => 'tcp',
        notrack => true,
        port    => 80,
        srange  => '$DOMAIN_NETWORKS',
    }

    if $has_tls == true {
        # Override niceness to run at -19 like php-fpm
        # TODO: use systemd::override
        file { '/etc/systemd/system/envoyproxy.service.d/niceness-override.conf':
            content => "[Service]\nNice=-19\nCPUAccounting=yes\n",
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            notify  => Exec['systemd daemon-reload for envoyproxy.service (envoyproxy.service)']
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

# @example security_cfgs, an array of Apache config blocks from hiera:
#   profile::lists::security_cfgs:
#     - |
#       # Reject posts to the foo route with
#       # a 403
#       RewriteEngine on
#       RewriteCond %{REQUEST_METHOD} POST
#       RewriteRule ^/bar/.*/foo$ - [F]
# @param security_cfgs additional apache config blocks to include
class profile::lists (
    Stdlib::Fqdn $lists_servername            = lookup('mailman::lists_servername'),
    Optional[String] $primary_host            = lookup('profile::lists::primary_host', {'default_value' => undef}),
    Optional[String] $standby_host            = lookup('profile::lists::standby_host', {'default_value' => undef}),
    Optional[Stdlib::IP::Address] $lists_ipv4 = lookup('profile::lists::ipv4', {'default_value' => undef}),
    Optional[Stdlib::IP::Address] $lists_ipv6 = lookup('profile::lists::ipv6', {'default_value' => undef}),
    Optional[String] $acme_chief_cert         = lookup('profile::lists::acme_chief_cert', {'default_value' => undef}),
    Optional[Stdlib::Fqdn] $db_host           = lookup('profile::lists::db_host', {'default_value' => undef}),
    Optional[String] $db_name                 = lookup('profile::lists::db_name', {'default_value' => undef}),
    Optional[String] $db_user                 = lookup('profile::lists::db_user', {'default_value' => undef}),
    Optional[String] $db_password             = lookup('profile::lists::db_password', {'default_value' => undef}),
    Optional[String] $webdb_name              = lookup('profile::lists::web::db_name', {'default_value' => undef}),
    Optional[String] $webdb_user              = lookup('profile::lists::web::db_user', {'default_value' => undef}),
    Optional[String] $webdb_password          = lookup('profile::lists::web::db_password', {'default_value' => undef}),
    Optional[String] $api_password            = lookup('profile::lists::api_password', {'default_value' => undef}),
    Optional[String] $web_secret              = lookup('profile::lists::web::secret', {'default_value' => undef}),
    Optional[String] $archiver_key            = lookup('profile::lists::archiver_key', {'default_value' => undef}),
    Optional[String] $memcached               = lookup('profile::lists::memcached', {'default_value' => undef}),
    Hash[String, String] $renamed_lists       = lookup('profile::lists::renamed_lists'),
    # Conditions to deny access to the lists web interface. Found in the private repository if needed.
    Array[String] $web_deny_conditions        = lookup('profile::lists::web_deny_conditions', {'default_value' => []}),
    Array[String] $security_cfgs              = lookup('profile::lists::security_cfgs', {'default_value' => []})
){
    include network::constants
    include privateexim::listserve

    # Disable mailman service on the sandby host
    $mailman_service_ensure = $facts['fqdn'] ? {
        $standby_host => 'stopped',
        default       => 'running',
    }

    class { '::mailman3':
        host           => $lists_servername,
        db_host        => $db_host,
        db_name        => $db_name,
        db_user        => $db_user,
        db_password    => $db_password,
        webdb_name     => $webdb_name,
        webdb_user     => $webdb_user,
        webdb_password => $webdb_password,
        api_password   => $api_password,
        archiver_key   => $archiver_key,
        web_secret     => $web_secret,
        memcached      => $memcached,
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)
    class { 'httpd':
        modules => [
            'ssl',
            'cgid',
            'headers',
            'rewrite',
            'alias',
            'setenvif',
            'auth_digest',
            'proxy_http',
            'proxy_uwsgi'
            ],
    }
    $apache_conf = {
      lists_servername    => $lists_servername,
      acme_chief_cert     => $acme_chief_cert,
      renamed_lists       => $renamed_lists,
      ssl_settings        => $ssl_settings,
      web_deny_conditions => $web_deny_conditions,
      security_cfgs       => $security_cfgs,
    }
    httpd::site { $lists_servername:
        content => epp('profile/lists/apache.conf.epp', $apache_conf),
    }

    profile::auto_restarts::service { 'apache2': }

    # Add files in /var/www (docroot)
    file { '/var/www':
        source  => 'puppet:///modules/profile/lists/docroot/',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => 'remote',
    }

    # Not using require_package so apt::pin may be applied
    # before attempting to install package.
    package { 'libapache2-mod-security2':
        ensure => present,
    }

    # Ensure that the CRS modsecurity ruleset is not used. it has not
    # yet been tested for compatibility with our mailman instance and may
    # cause breakage.
    file { '/etc/apache2/mods-available/security2.conf':
        ensure  => present,
        source  => 'puppet:///modules/profile/lists/modsecurity/security2.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['libapache2-mod-security2'],
    }

    mailalias { 'root': recipient => 'root@wikimedia.org' }

    # This will be a noop if $lists_ipv[46] are undef
    interface::alias { $lists_servername:
        ipv4 => $lists_ipv4,
        ipv6 => $lists_ipv6,
    }

    if $acme_chief_cert {
        class { 'sslcert::dhparam': }
        acme_chief::cert{ $acme_chief_cert:
            puppet_svc => 'apache2',
            key_group  => 'Debian-exim',
        }
    }

    if $::realm == 'labs' {
        $trusted_networks = ['172.16.0.0/12']
    }
    if $::realm == 'production' {
        $trusted_networks = $network::constants::aggregate_networks.filter |$x| {
            $x !~ /127.0.0.0|::1/
        }
    }

    class { 'spamassassin':
        required_score   => '4.0',
        use_bayes        => '0',
        bayes_auto_learn => '0',
        trusted_networks => $trusted_networks,
    }

    $list_outbound_ips = [
        pick($lists_ipv4, $facts['ipaddress']),
        pick($lists_ipv6, $facts['ipaddress6']),
    ]

    class { 'exim4':
        variant => 'heavy',
        config  => template('profile/exim/exim4.conf.mailman.erb'),
        filter  => template('profile/exim/system_filter.conf.mailman.erb'),
        require => [
            Class['spamassassin'],
            Interface::Alias[$lists_servername],
        ],
    }

    file { "/etc/exim4/aliases/${lists_servername}":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/exim/listserver_aliases.erb'),
        require => Class['exim4'],
    }

    exim4::dkim { $lists_servername:
        domain   => $lists_servername,
        selector => 'wikimedia',
        content  => secret("dkim/${lists_servername}-wikimedia.key"),
    }

    backup::set { 'var-lib-mailman3': }

    if $primary_host and $standby_host {
        rsync::quickdatacopy { 'var-lib-mailman':
            source_host         => $primary_host,
            dest_host           => $standby_host,
            auto_sync           => false,
            module_path         => '/var/lib/mailman',
            server_uses_stunnel => true,
        }
    }

    class { 'profile::lists::monitoring':
        lists_servername => $lists_servername,
        standby_host     => $standby_host
    }
    class { 'profile::lists::ferm': }
}

# === Class profile::mediawiki::httpd
#
# Installs and configures a web environment for mediawiki
#
# Only things not installed here:
# - Any specific website
# - Any special listening port
class profile::mediawiki::httpd(
    Integer $logrotate_retention = lookup('profile::mediawiki::httpd::logrotate_retention', {'default_value' => 30}),
    Optional[Integer] $workers_limit = lookup('profile::mediawiki::httpd::workers_limit', {'default_value' => undef}),
    String $cluster = lookup('cluster'),
    Optional[Boolean] $enable_forensic_log = lookup('profile::mediawiki::httpd::enable_forensic_log', {'default_value' => false}),
) {
    tag 'mediawiki', 'mw-apache-config'

    class { '::httpd':
        period              => 'daily',
        rotate              => $logrotate_retention,
        enable_forensic_log => $enable_forensic_log,
        modules             => [
            'alias',
            'authz_host',
            'autoindex',
            'dir',
            'expires',
            'headers',
            'mime',
            'rewrite',
            'setenvif',
            'proxy_fcgi',
        ]
    }
    systemd::unit{ 'apache2':
        content  => "[Service]\nCPUAccounting=yes\n",
        override => true,
    }

    # Modules we don't enable.
    # Note that deflate and filter are activated deep down in the
    # apache sites, we should probably move them here
    ::httpd::mod_conf { [
        'auth_basic',
        'authn_file',
        'authz_default',
        'authz_groupfile',
        'authz_user',
        'cgi',
        'deflate',
        'env',
        'negotiation',
        'reqtimeout',
    ]:
        ensure => absent,
    }

    file { '/etc/apache2/mods-available/expires.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/expires.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    file { '/etc/apache2/mods-available/autoindex.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/autoindex.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache2'],
        require => Package['apache2'],
    }


    file { '/etc/apache2/mods-available/setenvif.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/setenvif.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    file { '/etc/apache2/mods-available/mime.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/mime.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    # Add headers lost by mod_proxy_fastcgi
    ::httpd::conf { 'fcgi_headers':
        source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
        priority => 0,
    }

    # MPM configuration
    $threads_per_child = 25
    $apache_server_limit = $::processorcount
    $max_workers = $threads_per_child * $apache_server_limit
    if $workers_limit and is_integer($workers_limit) {
        $max_req_workers = min($workers_limit, $max_workers)
    }
    else {
        # Default if no override has been defined
        $max_req_workers = $max_workers
    }

    # TODO: move this to the httpd::mpm configuration once we can
    ::httpd::conf { 'worker':
        content => template('mediawiki/apache/worker.conf.erb')
    }
    class { '::httpd::mpm':
        mpm => 'worker'
    }


    file { '/etc/apache2/apache2.conf':
        content => template('mediawiki/apache/apache2.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache2'],
        require => Package['apache2'],
    }

    file { '/var/lock/apache2':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'root',
        mode   => '0755',
        before => File['/etc/apache2/apache2.conf'],
    }

    ::httpd::env { 'chuid_apache':
        vars    => {
            'APACHE_RUN_USER'  => $::mediawiki::users::web,
            'APACHE_RUN_GROUP' => $::mediawiki::users::web,
        },
        before  => Service['apache2'],
        require => Package['apache2'],
    }

    # Set the Server response header to be equal to the app server FQDN.
    package { 'libapache2-mod-security2':
        ensure => present
    }
    ::httpd::mod_conf { 'security2':
    }

    ::httpd::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }

    # Expose a SERVERGROUP variable to php-fpm
    ::httpd::conf { 'wikimedia_cluster':
        content => "SetEnvIf Request_URI \".\" SERVERGROUP=${cluster}\n"
    }
    # Starting with stretch libapache2-mod-security2 includes the following
    # in /etc/apache2/mods-enabled/security2.conf:
    #   # Include OWASP ModSecurity CRS rules if installed
    #   IncludeOptional /usr/share/modsecurity-crs/owasp-crs*.load
    # The directory /usr/share/modsecurity-crs is shipped by the
    # modsecurity-crs package, but it's only a Recommends: of
    # libapache2-mod-security2, so it doesn'get installed. And IncludeOptional
    # is only optional for the full path, so if /usr/share/modsecurity-crs doesn't
    # exist, it bails out and apache refuses to start/restart. As such, ship an
    # empty directory to make that include truly optional
    # In addition IncludeOptional expects a wildcard (which the original config
    # from modsecurity-crs doesn't ship, so we also need to ship an empty
    # stub config
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=878920
    # https://bz.apache.org/bugzilla/show_bug.cgi?id=57585
    # Once we're running a version of the patch proposed in Apache bugzilla, this
    # workaround can be removed

    file { '/usr/share/modsecurity-crs':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
        before => File['/usr/share/modsecurity-crs/owasp-crs.load'],
    }

    file { '/usr/share/modsecurity-crs/owasp-crs.load':
        owner   => 'root',
        content => '',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache2'],
    }
}

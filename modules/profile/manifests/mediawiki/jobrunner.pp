# @summary Sets up the basic functionalities of a jobrunner.
#
# @param statsd
#    The address of the statsd server.
#
# @param fcgi_port
#    If defined, sets up php-fpm to listen to that IP port instead of a unix socket
#
# @param fcgi_pool
#    Defines the name of the pool for php-fpm. Defaults to 'www'
#
# @param expose_endpoint
#    If true, the jobrunner endpoint is exposed to all clients. Defaults to false, should
#    only be set to true if no TLS setup is used (as in deployment-prep).
#
class profile::mediawiki::jobrunner(
    String $cluster = lookup('cluster'),
    String $statsd = lookup('statsd'),
    Optional[Stdlib::Port::User] $fcgi_port = lookup('profile::php_fpm::fcgi_port', {default_value => undef}),
    String $fcgi_pool = lookup('profile::mediawiki::fcgi_pool', {default_value => 'www'}),
    Boolean $expose_endpoint = lookup('profile::mediawiki::jobrunner::expose_endpoint', {default_value => false}),
    Array[Wmflib::Php_version] $php_versions = lookup('profile::mediawiki::php::php_versions', {'default_value' => ['7.2']}),
    Optional[Wmflib::Php_version] $default_php_version = lookup('profile::mediawiki::jobrunner::default_php_version', {'default_value' => undef})
) {
    # Parameters we don't need to override
    $port = 9005
    $local_only_port = 9006
    $versioned_port = php::fpm::versioned_port($fcgi_port, $php_versions)
    # The ordering of $fcgi_proxies determines the fallback php version in profile/mediawiki/jobrunner/site.conf.erb
    # via the mediawiki/apache/php_backend_selection.erb template function
    $ordered_php_versions = $default_php_version ? {
        undef => $php_versions,
        default => [$default_php_version] + $php_versions.filter |$x| { $x != $default_php_version}
    }
    $fcgi_proxies = $ordered_php_versions.map |$idx, $version| {
        $retval = [$version, mediawiki::fcgi_endpoint($versioned_port[$version], "${fcgi_pool}-${version}")]
    }
    # We're sharing template functions with mediawiki::web::vhost, so keep the same nomenclature.
    $php_fpm_fcgi_endpoint = $fcgi_proxies[0]
    $additional_fcgi_endpoints = $fcgi_proxies[1, -1]
    # Add headers lost by mod_proxy_fastcgi
    # The apache module doesn't pass along to the fastcgi appserver
    # a few headers, like Content-Type and Content-Length.
    # We need to add them back here.
    ::httpd::conf { 'fcgi_headers':
        source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
        priority => 0,
    }
    # Declare the proxies explicitly with retry=0
    httpd::conf { 'fcgi_proxies':
        ensure  => present,
        content => template('mediawiki/apache/fcgi_proxies.conf.erb')
    }

    # Expose a SERVERGROUP variable to php-fpm
    ::httpd::conf { 'wikimedia_cluster':
        content => "SetEnvIf Request_URI \".\" SERVERGROUP=${cluster}\n"
    }

    class { '::httpd':
        period  => 'daily',
        rotate  => 7,
        modules => [
            'alias',
            'authz_host',
            'autoindex',
            'deflate',
            'dir',
            'expires',
            'headers',
            'mime',
            'rewrite',
            'setenvif',
            'proxy_fcgi',
        ]
    }

    class { '::httpd::mpm':
        mpm => 'worker',
    }

    # Modules we don't enable.
    # TODO: We should also disable auth_basic, authn_file, authz_user
    # env, negotiation and reqtimeout
    ::httpd::mod_conf { [
        'authz_default',
        'authz_groupfile',
        'cgi',
    ]:
        ensure => absent,
    }

    httpd::conf { 'jobrunner_port':
        ensure   => present,
        priority => 1,
        content  => inline_template("# This file is managed by Puppet\nListen <%= @port %>\nListen <%= @local_only_port %>\n"),
    }

    httpd::site { 'php7_jobrunner':
        priority => 1,
        content  => template('profile/mediawiki/jobrunner/site.conf.erb'),
    }

    ::monitoring::service { 'jobrunner_http':
        description   => 'PHP7 jobrunner',
        check_command => 'check_http_jobrunner',
        retries       => 2,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Jobrunner',
    }

    # TODO: restrict this to monitoring and localhost only.
    ::ferm::service { 'mediawiki-jobrunner':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }
    # If no TLS proxy is present in front of the jobrunner, expose the port directly.
    if $expose_endpoint {
        ::ferm::service { 'mediawiki-jobrunner-notls':
            proto   => 'tcp',
            port    => $local_only_port,
            notrack => true,
            srange  => '$DOMAIN_NETWORKS',
        }
    }
}

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
    $statsd = hiera('statsd'),
    Optional[Wmflib::UserIpPort] $fcgi_port = hiera('profile::php_fpm::fcgi_port', undef),
    String $fcgi_pool = hiera('profile::mediawiki::fcgi_pool', 'www'),
    Boolean $expose_endpoint = hiera('profile::mediawiki::jobrunner::expose_endpoint', false),
) {
    # Parameters we don't need to override
    $port = 9005
    $local_only_port = 9006
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)

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

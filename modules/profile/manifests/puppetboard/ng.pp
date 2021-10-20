# @summary a profile to configure puppetboard
#  profile::puppetboard::ng is only around while we transition and will be moved
#  renamed when we are happy with it
#
# Actions:
#       Deploy Puppetboard
#       Install apache, uwsgi, configure reverse proxy to uwsgi
#
# Sample Usage:
#       include profile::puppetboard::ng
#
class profile::puppetboard::ng (
    Wmflib::Ensure                  $ensure                   = lookup('profile::puppetboard::ng::ensure'),
    Stdlib::Fqdn                    $vhost                    = lookup('profile::puppetboard::ng::vhost'),
    # puppet db settings
    Stdlib::Host                    $puppetdb_host            = lookup('profile::puppetboard::ng::puppetdb_host'),
    Stdlib::Port                    $puppetdb_port            = lookup('profile::puppetboard::ng::puppetdb_port'),
    Puppetboard::SSL_verify         $puppetdb_ssl_verify      = lookup('profile::puppetboard::ng::puppetdb_ssl_verify'),
    Optional[Stdlib::Unixpath]      $puppetdb_cert            = lookup('profile::puppetboard::ng::puppetdb_cert'),
    Optional[Stdlib::Unixpath]      $puppetdb_key             = lookup('profile::puppetboard::ng::puppetdb_key'),
    Optional[Enum['http', 'https']] $puppetdb_proto           = lookup('profile::puppetboard::ng::puppetdb_proto'),
    # Application settings
    String                          $page_title               = lookup('profile::puppetboard::ng:page_title'),
    Boolean                         $localise_timestamp       = lookup('profile::puppetboard::ng::localise_timestamp'),
    String                          $graph_type               = lookup('profile::puppetboard::ng::graph_type'),
    Array[String]                   $graph_facts_override     = lookup('profile::puppetboard::ng::graph_facts_override'),
    Array[String]                   $query_endpoints_override = lookup('profile::puppetboard::ng::query_endpoints_override'),
    Optional[String]                $secret_key               = lookup('profile::puppetboard::ng::secret_key'),

) {
    $uwsgi_port = 8001
    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    include profile::rsyslog::udp_json_logback_compat
    class {'puppetboard':
        ensure               => $ensure,
        puppetdb_host        => $puppetdb_host,
        puppetdb_port        => $puppetdb_port,
        puppetdb_ssl_verify  => $puppetdb_ssl_verify,
        puppetdb_cert        => $puppetdb_cert,
        puppetdb_key         => $puppetdb_key,
        puppetdb_proto       => $puppetdb_proto,
        page_title           => $page_title,
        localise_timestamp   => $localise_timestamp,
        graph_type           => $graph_type,
        graph_facts_override => $graph_facts_override,
    }


    # Puppetboard is controlled via a custom systemd unit (uwsgi-puppetboard),
    # so avoid the generic uwsgi sysvinit script shipped in the Debian package
    systemd::mask { 'mask_default_uwsgi_puppetboard':
        unit => 'uwsgi.service',
    }

    service::uwsgi { 'puppetboard':
        port       => $uwsgi_port,
        # This application is deployed by apt
        deployment => 'No Deploy',
        no_workers => 4,
        config     => {
            need-plugins => 'python3',
            wsgi         => 'puppetboard.wsgi',
            buffer-size  => 8096,
            vacuum       => true,
            http-socket  => "127.0.0.1:${uwsgi_port}",
            # T164034: make sure Python has a sane default encoding
            env          => [
                'LANG=C.UTF-8',
                'LC_ALL=C.UTF-8',
                'PYTHONENCODING=utf-8',
            ],
        },
    }

    profile::auto_restarts::service { 'uwsgi-puppetboard': }
    profile::auto_restarts::service { 'apache2': }

    ferm::service { 'apache2-http':
        proto => 'tcp',
        port  => '80',
    }

    class { 'httpd':
        modules => ['headers', 'rewrite', 'proxy', 'proxy_http'],
    }

    profile::idp::client::httpd::site { $vhost:
        # TODO: move template to hiera config
        vhost_content    => 'profile/idp/client/httpd-puppetboard-ng.erb',
        required_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=sre-admins,ou=groups,dc=wikimedia,dc=org',
        ],
        proxied_as_https => true,
        vhost_settings   => {'uwsgi_port' => $uwsgi_port},
    }
}

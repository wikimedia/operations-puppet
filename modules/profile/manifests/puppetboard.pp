# SPDX-License-Identifier: Apache-2.0
# @summary a profile to configure puppetboard
#  profile::puppetboard is only around while we transition and will be moved
#  renamed when we are happy with it
#
# Actions:
#       Deploy Puppetboard
#       Install apache, uwsgi, configure reverse proxy to uwsgi
#
# Sample Usage:
#       include profile::puppetboard
# @param ensure ensureable
# @param vhost the fqdn to use for the vhost
# @param vhost_staging vhost for use in the idp staging environment
# @param vhost_saml saml vhost for use in the idp staging environment
# @param puppetdb_host the puppetdb host
# @param puppetdb_port the puppetdb port
# @param puppetdb_ssl_verify how we should verify the puppetdb host
# @param puppetdb_cert the puppetdb certificate
# @param puppetdb_key the puppetdb key
# @param puppetdb_proto the protocol to use when connecting to puppetdb
# @param page_title the html title to use
# @param localise_timestamp wether to use localised time
# @param enable_catalog enable the catalog endpoint (could contain sensitive data)
# @param graph_type the graph type to use
# @param graph_facts_override list of facts to graph
# @param query_endpoints_override list of enabled query endpoints
# @param inventory_facts_override list of inventory facts
# @param secret_key the django secret key
class profile::puppetboard (
    Wmflib::Ensure                  $ensure                   = lookup('profile::puppetboard::ensure'),
    Stdlib::Fqdn                    $vhost                    = lookup('profile::puppetboard::vhost'),
    Optional[Stdlib::Fqdn]          $vhost_staging            = lookup('profile::puppetboard::vhost_staging'),
    Optional[Stdlib::Fqdn]          $vhost_saml               = lookup('profile::puppetboard::vhost_saml'),
    # puppet db settings
    Stdlib::Host                    $puppetdb_host            = lookup('profile::puppetboard::puppetdb_host'),
    Stdlib::Port                    $puppetdb_port            = lookup('profile::puppetboard::puppetdb_port'),
    Puppetboard::SSL_verify         $puppetdb_ssl_verify      = lookup('profile::puppetboard::puppetdb_ssl_verify'),
    Optional[Stdlib::Unixpath]      $puppetdb_cert            = lookup('profile::puppetboard::puppetdb_cert'),
    Optional[Stdlib::Unixpath]      $puppetdb_key             = lookup('profile::puppetboard::puppetdb_key'),
    Optional[Enum['http', 'https']] $puppetdb_proto           = lookup('profile::puppetboard::puppetdb_proto'),
    # Application settings
    String                          $page_title               = lookup('profile::puppetboard:page_title'),
    Boolean                         $localise_timestamp       = lookup('profile::puppetboard::localise_timestamp'),
    Boolean                         $enable_catalog           = lookup('profile::puppetboard::enable_catalog'),
    String                          $graph_type               = lookup('profile::puppetboard::graph_type'),
    Array[String]                   $graph_facts_override     = lookup('profile::puppetboard::graph_facts_override'),
    Array[String]                   $query_endpoints_override = lookup('profile::puppetboard::query_endpoints_override'),
    Hash[String, String]            $inventory_facts_override = lookup('profile::puppetboard::inventory_facts_override'),
    Optional[String]                $secret_key               = lookup('profile::puppetboard::secret_key'),

) {
    $uwsgi_port = 8001
    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    include profile::rsyslog::udp_json_logback_compat
    class {'puppetboard':
        ensure                   => $ensure,
        puppetdb_host            => $puppetdb_host,
        puppetdb_port            => $puppetdb_port,
        puppetdb_ssl_verify      => $puppetdb_ssl_verify,
        puppetdb_cert            => $puppetdb_cert,
        puppetdb_key             => $puppetdb_key,
        puppetdb_proto           => $puppetdb_proto,
        page_title               => $page_title,
        localise_timestamp       => $localise_timestamp,
        enable_catalog           => $enable_catalog,
        graph_type               => $graph_type,
        graph_facts_override     => $graph_facts_override,
        query_endpoints_override => $query_endpoints_override,
        inventory_facts_override => $inventory_facts_override,
        secret_key               => $secret_key,
    }


    # Puppetboard is controlled via a custom systemd unit (uwsgi-puppetboard),
    # so avoid the generic uwsgi sysvinit script shipped in the Debian package
    systemd::mask { 'mask_default_uwsgi_puppetboard':
        unit => 'uwsgi.service',
    }
    $nrpe_check_http = {
        'hostname' => 'localhost',
        'port'     => $uwsgi_port,
    }

    service::uwsgi { 'puppetboard':
        port            => $uwsgi_port,
        deployment      => 'No Deploy',
        nrpe_check_http => $nrpe_check_http,
        no_workers      => 4,
        config          => {
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

    # Service::Uwsgi['puppetboard'] ultimately creates Service['uwsgi-puppetboard']
    File[$puppetboard::config_file] ~> Service['uwsgi-puppetboard']
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

    if $vhost_staging {
        profile::idp::client::httpd::site { $vhost_staging:
            vhost_content    => 'profile/idp/client/httpd-puppetboard-ng.erb',
            required_groups  => [
                'cn=ops,ou=groups,dc=wikimedia,dc=org',
                'cn=sre-admins,ou=groups,dc=wikimedia,dc=org',
                'cn=idptest-users,ou=groups,dc=wikimedia,dc=org',
            ],
            proxied_as_https => true,
            cookie_secure    => 'On',
            vhost_settings   => {'uwsgi_port' => $uwsgi_port},
            environment      => 'staging',
            enable_monitor   => false,
        }
    }
    if $vhost_saml {
        profile::idp::client::httpd::site { $vhost_saml:
            vhost_content    => 'profile/idp/client/httpd-puppetboard-ng.erb',
            required_groups  => [
                'cn=ops,ou=groups,dc=wikimedia,dc=org',
                'cn=sre-admins,ou=groups,dc=wikimedia,dc=org',
                'cn=idptest-users,ou=groups,dc=wikimedia,dc=org',
            ],
            proxied_as_https => true,
            cookie_secure    => 'On',
            vhost_settings   => {'uwsgi_port' => $uwsgi_port},
            validate_saml    => true,
            environment      => 'staging',
            enable_monitor   => false,
        }
    }
}

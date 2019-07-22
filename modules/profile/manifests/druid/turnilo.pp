# Class: profile::druid::turnilo
#
# Install and configure the Druid's Turnilo nodejs UI
#
# [*druid_clusters*]
#
# [*port*]
#   The port used by Turnilo to accept HTTP connections.
#   Default: 9091
#
# [*monitoring_enabled*]
#   Enable monitoring for the Turnilo service.
#   Default: false
#
# [*contact_group*]
#   Monitoring's contact grup.
#   Default: 'analytics'
#
class profile::druid::turnilo(
    $druid_clusters     = hiera('profile::druid::turnilo::druid_clusters'),
    $port               = hiera('profile::druid::turnilo::port', 9091),
    $monitoring_enabled = hiera('profile::druid::turnilo::monitoring_enabled', false),
    $contact_group      = hiera('profile::druid::turnilo::contact_group', 'analytics'),
    $proxy_enabled      = hiera('profile::druid::turnilo::proxy_enabled', true),
    Hash $ldap_config   = lookup('ldap', Hash, hash, {}),
) {
    class { 'turnilo':
        druid_clusters => $druid_clusters,
    }

    class { '::httpd':
        modules => ['proxy_http',
                    'proxy',
                    'auth_basic',
                    'authnz_ldap']
    }

    class { '::passwords::ldap::production': }

    ferm::service { 'turnilo-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    monitoring::service { 'turnilo':
        description   => 'turnilo',
        check_command => "check_tcp!${port}",
        contact_group => $contact_group,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Turnilo-Pivot',
    }

    if $proxy_enabled {
        $server_name = $::realm ? {
            'production' => 'turnilo.wikimedia.org',
            'labs'       => "turnilo-${::labsproject}.${::site}.wmflabs",
        }

        class { 'turnilo::proxy':
            server_name          => $server_name,
            ldap_server          => $ldap_config['ro-server'],
            ldap_server_fallback => $ldap_config['ro-server-fallback'],
        }
    }
}

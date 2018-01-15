# == Class: profile::grafana::production
#
# Grafana is a dashboarding webapp for Graphite.
# It powers <https://grafana.wikimedia.org>.
#
class profile::grafana::production {
    include ::passwords::grafana::production

    class { '::profile::grafana':
        readonly_domain         => 'grafana.wikimedia.org',
        admin_domain            => 'grafana-admin.wikimedia.org',
        secret_key              => $passwords::grafana::production::secret_key,
        admin_password          => $passwords::grafana::production::admin_password,
        ldap_editor_description => 'nda/ops/wmf/grafana-admin',
        ldap_editor_groups      => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=grafana-admin,ou=groups,dc=wikimedia,dc=org',
        ]
    }

    grafana::dashboard { 'varnish-http-errors':
        source => 'puppet:///modules/grafana/dashboards/varnish-http-errors',
    }

    grafana::dashboard { 'varnish-aggregate-client-status-codes':
        source => 'puppet:///modules/grafana/dashboards/varnish-aggregate-client-status-codes',
    }

    grafana::dashboard { 'swift':
        source => 'puppet:///modules/grafana/dashboards/swift',
    }
    grafana::dashboard { 'server-board':
        source => 'puppet:///modules/grafana/dashboards/server-board',
    }
}

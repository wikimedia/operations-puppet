# == Class: role::grafana::labs
#
# Grafana is a dashboarding webapp for Graphite.
# It powers <https://grafana-labs.wikimedia.org>.
#
class role::grafana::labs {
    include ::passwords::grafana::labs

    class { '::role::grafana::base':
        readonly_domain         => 'grafana-labs.wikimedia.org',
        admin_domain            => 'grafana-labs-admin.wikimedia.org',
        secret_key              => $passwords::grafana::labs::secret_key,
        admin_password          => $passwords::grafana::labs::admin_password,
        ldap_editor_description => 'LDAP Users (Wikitech)',
        ldap_editor_groups      => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
            'cn=grafana-admin,ou=groups,dc=wikimedia,dc=org',
            'cn=project-bastion,ou=groups,dc=wikimedia,dc=org'
        ]
    }

    # https://phabricator.wikimedia.org/T141636
    git::clone { 'grafana/simple-json-datasource':
        ensure    => 'latest',
        branch    => '3.0',
        directory => '/usr/share/grafana/public/app/plugins/datasource/simple-json-datasource',
        origin    => 'operations/software/grafana/simple-json-datasource',
        require   => Package['grafana'],
    }
}

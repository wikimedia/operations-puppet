# == Class: role::grafana
#
# Grafana is a dashboarding webapp for Graphite.
# It powers <https://grafana.wikimedia.org>.
#
class role::grafana {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::rewrite

    include ::role::backup::host

    include ::passwords::grafana
    include ::passwords::ldap::production

    class { '::grafana':
        config => {
            # Configuration settings for /etc/grafana/grafana.ini.
            # See <http://docs.grafana.org/installation/configuration/>.

            # Only listen on loopback, because we'll have a local Apache
            # instance acting as a reverse-proxy.
            'server'     => {
                http_addr   => '127.0.0.1',
                domain      => 'grafana.wikimedia.org',
                protocol    => 'http',
                enable_gzip => true,
            },

            # Grafana needs a database to store users and dashboards.
            # sqlite3 is the default, and it's perfectly adequate.
            'database'   => {
                type => 'sqlite3',
                path => 'grafana.db',
            },

            'security'   => {
                secret_key     => $passwords::grafana::secret_key,
                admin_password => $passwords::grafana::admin_password,
            },

            # Disabled auth.basic, because it conflicts with auth.proxy.
            # See <https://github.com/grafana/grafana/issues/2357>
            'auth.basic' => {
                enabled => false,
            },

            # Automatically create an account for users and authenticate
            # them based on the X-WEBAUTH-USER. We use mod_rewrite to
            # rewrite the REMOTE_USER env var set by mod_authnz_ldap into
            # X-WEBAUTH-USER.
            'auth.proxy' => {
                enabled      => true,
                header_name  => 'X-WEBAUTH-USER',
                auto_sign_up => true,
            },

            # Since we require ops / nda / wmf LDAP group membership
            # to log in to Grafana, we can assume all users are trusted,
            # and can assign to them the 'Editor' role (rather than
            # 'Viewer', the default).
            'users'      => {
                auto_assign_org_role => 'Editor',
                allow_org_create     => false,
                allow_sign_up        => false,
            },

            # Because we enable `auth.proxy` (see above), if session data
            # is lost, Grafana will simply create a new session on the next
            # request, so it's OK for session storage to be volatile.
            'session'    => {
                provider      => 'memory',
                cookie_secure => true,
            },

            # Don't send anonymous usage stats to stats.grafana.org.
            # We don't like it when software phones home.
            'analytics'  => {
                reporting_enabled => false,
            },
        },
    }

    # LDAP configuration. Interpolated into the Apache site template
    # to provide mod_authnz_ldap-based user authentication.
    $auth_ldap = {
        name          => 'nda/ops/wmf',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => 'ldaps://ldap-eqiad.wikimedia.org ldap-codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    # Serve Grafana via two different vhosts:
    #
    # - grafana.wikimedia.org (read-only, but accessible to all)
    # - grafana-admin.wikimedia.org (read/write, but requires LDAP)
    #

    apache::site { 'grafana.wikimedia.org':
        content => template('apache/sites/grafana.wikimedia.org.erb'),
        require => Class['::grafana'],
    }

    monitoring::service { 'grafana':
        description   => 'grafana.wikimedia.org',
        check_command => 'check_http_url!grafana.wikimedia.org!/',
    }

    apache::site { 'grafana-admin.wikimedia.org':
        content => template('apache/sites/grafana-admin.wikimedia.org.erb'),
        require => Class['::grafana'],
    }

    monitoring::service { 'grafana-admin':
        description   => 'grafana-admin.wikimedia.org',
        check_command => 'check_http_url!grafana-admin.wikimedia.org!/',
    }

    backup::set { 'var-lib-grafana':
        require => Class['::grafana'],
    }
}

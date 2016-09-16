# == Class: role::grafana::base
#
# Grafana is a dashboarding webapp for Graphite.
# This is a base role that should not be applied by itself
#
class role::grafana::base(
    $readonly_domain,
    $admin_domain,
    $secret_key,
    $admin_password,
    $ldap_editor_description,
    $ldap_editor_groups,
) {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::rewrite

    include ::role::backup::host

    include ::passwords::ldap::production

    include base::firewall

    class { '::grafana':
        config => {
            # Configuration settings for /etc/grafana/grafana.ini.
            # See <http://docs.grafana.org/installation/configuration/>.

            # Only listen on loopback, because we'll have a local Apache
            # instance acting as a reverse-proxy.
            'server'     => {
                http_addr   => '127.0.0.1',
                domain      => $readonly_domain,
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
                secret_key       => $secret_key,
                admin_password   => $admin_password,
                disable_gravatar => true,
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

            # Since we require users to be members of a trusted LDAP group
            # membership to log in to Grafana, we can assume all users are
            # trusted, and can assign to them the 'Editor' role (rather
            # than 'Viewer', the default).
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

            # We don't like it when software phones home.
            # Don't send anonymous usage stats to stats.grafana.org,
            # and don't check for updates automatically.
            'analytics'  => {
                reporting_enabled => false,
                check_for_updates => false,
            },

            # Also, don't allow publishing to raintank.io.
            'snapshots'  => {
                external_enabled => false,
            },
        },
    }

    ferm::service { 'grafana_http':
        proto => 'tcp',
        port  => '80',
    }

    # LDAP configuration. Interpolated into the Apache site template
    # to provide mod_authnz_ldap-based user authentication.
    $auth_ldap = {
        name          => $ldap_editor_description,
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => 'ldaps://ldap-labs.eqiad.wikimedia.org ldap-labs.codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        groups        => $ldap_editor_groups,
    }

    # Override the default home dashboard with something custom.
    # This will be doable via a preference in the future. See:
    # <https://groups.io/org/groupsio/grafana/thread/home_dashboard_in_grafana_2_0/43631?threado=120>
    file { '/usr/share/grafana/public/dashboards/home.json':
        source  => 'puppet:///modules/grafana/home.json',
        require => Package['grafana'],
        notify  => Service['grafana-server'],
    }

    # move file to module?
    # lint:ignore:puppet_url_without_modules
    file { '/usr/share/grafana/public/img/grafana_icon.svg':
        source  => 'puppet:///files/misc/wikimedia-logo.svg',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['grafana'],
    }
    # lint:endignore

    # We disable account creation, because accounts are created
    # automagically based on the X-WEBAUTH-USER, which is either set
    # to the LDAP user (if accessing the site via the grafana-admin vhost)
    # or 'Anonymous'. But we need to have an 'Anonymous' user in the first
    # place. To accomplish that, we use a small Python script that directly
    # directly inserts the user into Grafana's sqlite database.
    #
    # If you are reading this comment because something broke and you are
    # trying to figure out why, it is probably because Grafana's database
    # schema changed. You can nuke this script and achieve the same result
    # by temporarily commenting out the allow_signups line in
    # /etc/grafana/grafana.ini and removing the restriction on POST and
    # PUT in /etc/apache2/sites-enabled/50-grafana.wikimedia.org.conf,
    # and then creating the user manually via the web interface.

    require_package('python-sqlalchemy')

    file { '/usr/local/sbin/grafana_create_anon_user':
        source  => 'puppet:///modules/grafana/grafana_create_anon_user',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => [
            Service['grafana-server'],
            Package['python-sqlalchemy'],
        ],
    }

    exec { '/usr/local/sbin/grafana_create_anon_user --create':
        unless  => '/usr/local/sbin/grafana_create_anon_user --check',
        require => File['/usr/local/sbin/grafana_create_anon_user'],
    }

    # Serve Grafana via two different vhosts:
    #
    # - grafana.wikimedia.org (read-only, but accessible to all)
    # - grafana-admin.wikimedia.org (read/write, but requires LDAP)
    #

    apache::site { $readonly_domain:
        content => template('role/apache/sites/grafana-readonly.erb'),
        require => Class['::grafana'],
    }

    monitoring::service { 'grafana':
        description   => $readonly_domain,
        check_command => "check_http_url!${readonly_domain}!/",
    }

    apache::site { $admin_domain:
        content => template('role/apache/sites/grafana-admin.erb'),
        require => Class['::grafana'],
    }

    monitoring::service { 'grafana-admin':
        description   => $admin_domain,
        check_command => "check_http_unauthorized!${admin_domain}!/",
    }

    backup::set { 'var-lib-grafana':
        require => Class['::grafana'],
    }
}

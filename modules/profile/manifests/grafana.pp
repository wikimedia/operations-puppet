# == Class: profile::grafana
#
# Grafana is a dashboarding webapp for Graphite.
#
class profile::grafana (
    $readonly_domain=hiera('profile::grafana::readonly_domain'),
    $admin_domain=hiera('profile::grafana::admin_domain', undef),
    $secret_key=hiera('profile::grafana::secret_key'),
    $admin_password=hiera('profile::grafana::admin_password'),
    $ldap_editor_description=hiera('profile::grafana::ldap_editor_description'),
    $ldap_editor_groups=hiera('profile::grafana::ldap_edit_groups'),
    $config=hiera('profile::grafana::config', {}),
    $ldap=hiera('profile::grafana::ldap', undef),
) {

    include ::profile::backup::host

    include ::passwords::ldap::production

    include ::profile::base::firewall

    # This isn't needed by grafana, but is handy for inspecting its database.
    require_package(['sqlite3'])

    $base_config = {
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
            'type' => 'sqlite3',
            'path' => 'grafana.db',
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
    }
    $end_config = deep_merge($base_config, $config)

    class { '::grafana':
        config => $end_config,
        ldap   => $ldap,
    }

    ferm::service { 'grafana_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
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

    file { '/usr/share/grafana/public/img/grafana_icon.svg':
        source  => 'puppet:///modules/role/grafana/wikimedia-logo.svg',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['grafana'],
    }

    # Note: As of 2018-06-27 parts of this are no longer true, at least for
    # production. Production now creates accounts natively in grafana via LDAP
    # integration.
    #
    # We disable account creation, because accounts are created
    # automagically based on the X-WEBAUTH-USER, which is either set
    # to the LDAP user (if accessing the site via the admin grafana vhost)
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
        require => Package['python-sqlalchemy'],
    }

    exec { '/usr/local/sbin/grafana_create_anon_user --create':
        unless  => '/usr/local/sbin/grafana_create_anon_user --check',
        require => [
            Service['grafana-server'],
            File['/usr/local/sbin/grafana_create_anon_user'],
        ]
    }

    # Serve Grafana via two different vhosts:
    #
    # - $readonly_domain (read-only, but accessible to all)
    # - $admin_domain (read/write, but requires LDAP)
    #

    httpd::site { $readonly_domain:
        content => template('profile/apache/sites/grafana-readonly.erb'),
        require => Class['::grafana'],
    }

    monitoring::service { 'grafana':
        description   => $readonly_domain,
        check_command => "check_http_url!${readonly_domain}!/",
    }

    if $admin_domain {
        httpd::site { $admin_domain:
            content => template('profile/apache/sites/grafana-admin.erb'),
            require => Class['::grafana'],
        }

        monitoring::service { 'grafana-admin':
            description   => $admin_domain,
            check_command => "check_http_unauthorized!${admin_domain}!/",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Grafana.wikimedia.org',
        }
    }

    backup::set { 'var-lib-grafana':
        require => Class['::grafana'],
    }

    # https://phabricator.wikimedia.org/T147329
    # We clone this, but need to symlink into the 'dist' directory for plugin to actually work
    git::clone { 'operations/software/grafana/simple-json-datasource':
        ensure    => present,
        branch    => '3.0',
        directory => '/usr/share/grafana/public/app/plugins/datasource/simple-json-datasource',
        require   => Package['grafana'],
    }

    file { '/usr/share/grafana/public/app/plugins/datasource/datasource-plugin-genericdatasource':
        ensure  => link,
        target  => '/usr/share/grafana/public/app/plugins/datasource/simple-json-datasource/dist',
        require => Git::Clone['operations/software/grafana/simple-json-datasource'],
    }
}

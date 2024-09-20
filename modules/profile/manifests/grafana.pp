# SPDX-License-Identifier: Apache-2.0

# @summary Grafana is a dashboarding webapp for Graphite.
# @param secret_key the secret key
# @param admin_password the admin password
# @param config a hash of config settings.  This paramater uses a 'deep' merge strategy
# @param ldap a Hash of ldap servers
# @param execute_alerts boolean enable alert execution engine
# @param wpt_graphite_proxy_port If set  Configure a local Apache which will serve as
#        a reverse proxy for WebPageTest's external Graphite instance.
# @param logo_file_source source of the logo file to use
class profile::grafana (
    String                 $admin_password          = lookup('profile::grafana::admin_password'),
    Hash                   $config                  = lookup('profile::grafana::config'),
    Stdlib::Fqdn           $domain                  = lookup('profile::grafana::domain'),
    Optional[Stdlib::Fqdn] $domainrw                = lookup('profile::grafana::domainrw',                { 'default_value' => undef }),
    Boolean                $enable_cas              = lookup('profile::grafana::enable_cas'),
    Boolean                $enable_loki             = lookup('profile::grafana::enable_loki',             { 'default_value' => false }),
    Boolean                $execute_alerts          = lookup('profile::grafana::execute_alerts',          { 'default_value' => true }),
    Hash                   $ldap                    = lookup('profile::grafana::ldap',                    { 'default_value' => {} }),
    String                 $secret_key              = lookup('profile::grafana::secret_key'),
    Array[Stdlib::Fqdn]    $server_aliases          = lookup('profile::grafana::server_aliases'),
    Optional[Stdlib::Port] $wpt_graphite_proxy_port = lookup('profile::grafana::wpt_graphite_proxy_port', { 'default_value' => undef }),
    Optional[Stdlib::Port] $wpt_json_proxy_port     = lookup('profile::grafana::wpt_json_proxy_port',     { 'default_value' => undef }),
    Stdlib::Filesource     $logo_file_source        = lookup('profile::grafana::logo_file_source',        { 'default_value' => 'puppet:///modules/profile/grafana/logo/wikimedia-logo.svg' }),
    # This external config needs to be fetched as we handle the envoy autorestart in this profile
    Wmflib::Ensure         $envoy_ensure            = lookup('profile::envoy::ensure',                    {'default_value' => 'present'})
) {
    include passwords::ldap::production

    if ($enable_loki) {
        include profile::grafana::loki
    }
    # This isn't needed by grafana, but is handy for inspecting its database.
    ensure_packages(['sqlite3', 'grafana-plugins'])

    $base_config = {
        # Configuration settings for /etc/grafana/grafana.ini.
        # See <http://docs.grafana.org/installation/configuration/>.

        # Only listen on loopback, because we'll have a local Apache
        # instance acting as a reverse-proxy.
        'server'     => {
            http_addr   => '127.0.0.1',
            domain      => $domain,
            protocol    => 'http',
            enable_gzip => true,
            root_url    => 'https://%(domain)s/',
        },

        # Grafana needs a database to store users and dashboards.
        # sqlite3 is the default, and it's perfectly adequate.
        # "wal" new in Grafana 9.4+ to address "database is locked" errors (T345362)
        'database'   => {
            'type' => 'sqlite3',
            'path' => 'grafana.db',
            'wal'  => true,
        },

        'security'   => {
            secret_key       => $secret_key,
            admin_password   => $admin_password,
            disable_gravatar => true,
            cookie_secure    => true,
        },

        # Disabled auth.basic, because it conflicts with auth.proxy.
        # See <https://github.com/grafana/grafana/issues/2357>
        'auth.basic' => {
            enabled => false,
        },

        'auth.proxy' => {
            enabled => false,
        },

        'alerting' => {
            execute_alerts => $execute_alerts
        },

        # Since we require users to be members of a trusted LDAP group
        # membership to log in to Grafana, we can assume all users are
        # trusted, and can assign to them the 'Editor' role (rather
        # than 'Viewer', the default).
        'users'      => {
            auto_assign_org_role => 'Editor',
            allow_org_create     => false,
            allow_sign_up        => false,
            default_theme        => 'light',
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

    firewall::service { 'grafana_http':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['CACHES'],
    }

    file { '/usr/share/grafana/public/dashboards/home.json':
        ensure => absent,
    }

    file { '/usr/share/grafana/public/img/grafana_icon.svg':
        source  => $logo_file_source,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['grafana'],
    }

    # read/write access for editors/admins using CAS
    if $enable_cas {
        include profile::idp::client::httpd
    }

    # read-only, public access
    httpd::site { $domain:
        content => template('profile/apache/sites/grafana.erb'),
        require => Class['::grafana'],
    }

    httpd::conf { 'metrics_acl':
        ensure => absent,
    }

    file { '/etc/apache2/prometheus_metrics_acl':
        content => template('profile/apache/prometheus_metrics_acl.erb'),
    }

    httpd::mod_conf { 'remoteip':
        ensure => present,
    }

    # Configure a local Apache which will serve as a reverse proxy for Performance Testing
    # Graphite instance. That Apache uses our outbound proxy as its forward
    # proxy for those requests. Despite being a mouthful, this seems preferable to setting the
    # http_proxy env var for the grafana process itself (and then also needing to set
    # no_proxy for every datasource URL other than the one of the perf-team Graphite).
    # https://phabricator.wikimedia.org/T231870
    # Could be retired if https://github.com/grafana/grafana/issues/15045 is implemented.
    if $wpt_graphite_proxy_port {
        httpd::site { 'proxy-wpt-graphite':
            content => template('profile/apache/sites/grafana-wpt-graphite-proxy.erb'),
        }
    }

    # Configure a local Apache which will serve as a reverse proxy for Performance Team's
    # JSON meta data used for WebPageTest and WebPageReplay tests. That Apache uses our
    # outbound proxy as its forward proxy for those requests.
    # https://phabricator.wikimedia.org/T304583
    # Could be retired if https://github.com/grafana/grafana/issues/15045 is implemented.
    if $wpt_json_proxy_port {
        httpd::site { 'proxy-wpt-json':
            content => template('profile/apache/sites/grafana-wpt-json-proxy.erb'),
        }
    }

    backup::set { 'var-lib-grafana':
        require => Class['::grafana'],
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy':
        ensure => $envoy_ensure,
    }
}

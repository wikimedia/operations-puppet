# == Class profile::swap
# SWAP - Simple Web Analytics Platform
# Sets up a JupyterHub instance with WMF LDAP authentication
# and authorization in certain POSIX groups.
#
# == Parameters
#
#   [*ldap_groups*]
#       If given, users will authenticate with WMF LDAP, and only be authorized
#       if they are in these groups.  Default wmf, nda
#
#   [*ldap_config*]
#       LDAP production config containing the read-only endpoint to use.
#
#   [*rsync_hosts_allow*]
#       If given, an rsync server module will be set up to allow these hosts
#       to rsync between home directories.
#
#   [*krb_credential_cache*]
#       If given, the Systemd Spawner class will be extended to add the KRB5CCNAME
#       environment variable to the default environment for the ephemeral systemd units
#       used for user kernels. The krb_credential_cache must be a string containing the
#       literal "{}", used as placeholder for the user id. For example: "/run/user/{}/krb_cred"
#       If you change this remember to check what value is set for the default credential cache
#       in profile::kerberos::client.
#       Default: undef (if not provided the jvm will look for /tmp/krb5_{}).
#
class profile::swap(
    Array[String] $ldap_groups = lookup('profile::swap::allowed_ldap_groups', { 'default_value' => [
        'cn=nda,ou=groups,dc=wikimedia,dc=org',
        'cn=wmf,ou=groups,dc=wikimedia,dc=org',
    ]}),
    Optional[Hash] $ldap_config = lookup('ldap', Hash, hash, {}),
    Optional[Array[Stdlib::Host]] $rsync_hosts_allow = lookup('profile::swap::rsync_hosts_allow', {'default_value' => undef}),
    Array[Stdlib::Host] $dumps_servers = lookup('dumps_dist_nfs_servers'),
    Stdlib::Host $dumps_active_server = lookup('dumps_dist_active_web'),
    Boolean $push_published = lookup('profile::swap::push_published', { 'default_value' => true }),
    Boolean $use_dumps_mounts = lookup('profile::swap::use_dumps_mounts', { 'default_value' => true }),
    Boolean $deploy_research_cred = lookup('profile::swap::deploy_research_cred', { 'default_value' => true }),
    Optional[String] $krb_credential_cache = lookup('profile::swap::krb_credential_cache', {'default_value' => undef }),
) {
    if $use_dumps_mounts {
        # Mount mediawiki dataset dumps. T176091
        class { '::statistics::dataset_mount':
            dumps_servers       => $dumps_servers,
            dumps_active_server => $dumps_active_server,
        }
    }

    # If admin_groups not set in profile::standard, then use labsproject in labs, or wikidev in production.
    $default_posix_groups = $::realm ? {
        'labs'       => ["project-${::labsproject}"],
        'production' => ['wikidev'],
    }
    include profile::standard
    $posix_groups = $profile::standard::admin_groups.empty ? {
        true   => $default_posix_groups,
        default => $profile::standard::admin_groups,
    }

    # Use a web_proxy in production, and include the researchers db password.
    if $::realm == 'production' {
        $web_proxy = "http://webproxy.${::site}.wmnet:8080"

        if $deploy_research_cred {
            statistics::mysql_credentials { 'research':
                group => 'researchers',
            }
            statistics::mysql_credentials { 'analytics-research':
                group => 'analytics-privatedata-users',
            }
        }

        if $push_published {
            # Include an rsync from /srv/published to
            # thorium.eqiad.wmnet to publish data at
            # analytics.wikimedia.org/published.
            class { '::statistics::rsync::published': }
        }
    }
    else {
        $web_proxy = undef
    }

    class { 'jupyterhub':
        ldap_server           => $ldap_config['ro-server'],
        ldap_bind_dn_template => 'uid={username},ou=people,dc=wikimedia,dc=org',
        # LDAP authenticate anyone in these groups.
        ldap_groups           => $ldap_groups,
        # But only allow those in these posix groups to log in to jupyterhub.
        posix_groups          => $posix_groups,
        web_proxy             => $web_proxy,
        krb_credential_cache  => $krb_credential_cache,
    }

    # Files deleted via the notebook interface are moved to a special
    # Trash directory and never removed.
    cron { 'clean_jupyter_local_trash':
        command => '/usr/bin/find /srv/home -type d -regex "/srv/home/.+/\.local/share/Trash" -exec rm -rf {} >/dev/null 2>&1 \;',
        minute  => 0,
    }

    if $rsync_hosts_allow {
        # Allow rsyncing between home directories.
        class { '::rsync::server': }

        # Set up an rsync module
        # (in /etc/rsyncd.conf) for /home.
        rsync::server::module { 'home':
            path        => '/home',
            read_only   => 'yes',
            list        => 'yes',
            # Set uid/gid to false to override rsync::server::module's default of 0/0
            uid         => false,
            gid         => false,
            hosts_allow => $rsync_hosts_allow,
            auto_ferm   => true,
        }
    }
}

# SPDX-License-Identifier: Apache-2.0
# @summary profile to install the requestctl web interface
#
# @param root_token the root token to use for requestctl.
# @param csrf_shared_secret str a secret key for CSRF protection
# @param db_user the database user to use for requestctl's database connection
# @param db_password the database password to use for requestctl's database connection
# @param db_master_dc the datacenter where the master database is located. Defaults to 'eqiad'.
# @param api_token_encryption_key the key to use for encrypting api tokens in the database.
class profile::conftool::hiddenparma (
    String $root_token = lookup('profile::conftool::hiddenparma::root_token'),
    String $csrf_shared_secret = lookup('profile::conftool::hiddenparma::csrf_shared_secret'),
    String $db_user = lookup('profile::conftool::hiddenparma::db_user'),
    String $db_password = lookup('profile::conftool::hiddenparma::db_password'),
    String $db_master_dc = lookup('db_m2_primary_dc', { default_value => 'eqiad' }),
    String $api_token_encryption_key = lookup('profile::conftool::hiddenparma::api_token_encryption_key'),
) {
    # TODO: remove once absented
    file { '/etc/HIDDENPARMA/api_tokens.json':
        ensure  => absent,
    }

    # The passwords::etcd class is required by conftool::client, but we want to make the dependency explicit.
    require passwords::etcd
    require profile::conftool::client
    # Create the /srv/deployment directory if it doesn't exist
    if (!defined(File['/srv/deployment'])) {
        file { '/srv/deployment':
            ensure => directory,
        }
    }
    # Database connection info
    $db_dsn = "mariadb+pymysql://${db_user}:${db_password}@m2-master.${db_master_dc}.wmnet/requestctl?charset=utf8mb4"

    $user = 'deploy-hiddenparma'
    file { '/etc/default/hiddenparma':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/conftool/hiddenparma-default.erb'),
    }

    # TODO: maybe create a "requestctl root" user for etcd?
    $etcd_user = 'conftool'
    $etcd_pwd = $passwords::etcd::accounts[$etcd_user]

    file { '/var/lib/deploy-hiddenparma/.etcdrc':
        ensure  => file,
        owner   => 'deploy-hiddenparma',
        group   => 'deploy-hiddenparma',
        mode    => '0400',
        content => to_yaml(
            {
                'username' => $etcd_user,
                'password' => $etcd_pwd,
            }
        ),
        notify  => Service['hiddenparma'],
    }

    fastapi::application { 'hiddenparma':
        port   => 8080,
    }

    profile::auto_restarts::service { 'hiddenparma': }

    file { '/etc/HIDDENPARMA':
        ensure  => directory,
        owner   => $user,
        group   => $user,
        mode    => '0550',
        require => Fastapi::Application['hiddenparma'],
    }

    file { '/etc/HIDDENPARMA/policies.yaml':
        ensure => file,
        owner  => $user,
        group  => $user,
        mode   => '0440',
        source => 'puppet:///modules/profile/conftool/hp-policies.yaml',
    }
    # Apache and CAS auth setup
    profile::idp::client::httpd::site { 'requestctl.wikimedia.org':
        require         => [
            Acme_chief::Cert['icinga'],
        ],
        vhost_content   => 'profile/conftool/httpd-hiddenparma.conf.erb',
        # Only full roots are granted read-write access in the configuration.
        required_groups => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
        vhost_settings  => { proxy_pass => 'http://localhost:8080' },
    }
}

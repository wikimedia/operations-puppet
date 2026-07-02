# SPDX-License-Identifier: Apache-2.0
# @summary profile to install the requestctl web interface
#
# @param root_token the root token to use for requestctl.
# @param csrf_shared_secret str a secret key for CSRF protection
# @param db_user the database user to use for requestctl's database connection
# @param db_password the database password to use for requestctl's database connection
# @param db_master_dc the datacenter where the master database is located. Defaults to 'eqiad'.
# @param api_token_encryption_key the key to use for encrypting api tokens in the database.
# @param session_secret_key the key to use for encrypting session cookies. To be defined in private hiera
# @param known_fingerprints a hash of known fingerprints to be used to warn users not to block known browsers by accident.
class profile::conftool::hiddenparma (
    String $root_token = lookup('profile::conftool::hiddenparma::root_token'),
    String $csrf_shared_secret = lookup('profile::conftool::hiddenparma::csrf_shared_secret'),
    String $db_user = lookup('profile::conftool::hiddenparma::db_user'),
    String $db_password = lookup('profile::conftool::hiddenparma::db_password'),
    String $db_master_dc = lookup('db_m2_primary_dc', { default_value => 'eqiad' }),
    String $api_token_encryption_key = lookup('profile::conftool::hiddenparma::api_token_encryption_key'),
    String $session_secret_key = lookup('profile::conftool::hiddenparma::session_secret_key'),
    Hash[String, Hash[String, Array[String]]] $known_fingerprints = lookup('profile::conftool::hiddenparma::known_fingerprints', { default_value => {} }),
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

    # All the following parameters do not need changing ever as of now. If the need ever surfaced, move them to class parameters
    $user = 'deploy-hiddenparma'
    $virtual_host = 'requestctl.wikimedia.org'

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

    $default_ratelimits = {
        'text'   => 3000,  # 50 rps on average
        'upload' => 600,   # 10 rps on average
    }

    file { '/etc/HIDDENPARMA/default_ratelimits.yaml':
        ensure  => file,
        owner   => $user,
        group   => $user,
        mode    => '0440',
        content => to_yaml($default_ratelimits),
    }

    file { '/etc/HIDDENPARMA/known_fingerprints.yaml':
        ensure  => file,
        owner   => $user,
        group   => $user,
        mode    => '0440',
        content => to_yaml($known_fingerprints),
    }
    # Apache setup
    $document_root = '/var/www'
    $proxy_pass = 'http://localhost:8080'
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    httpd::site { $virtual_host:
        content => template('profile/conftool/httpd-hiddenparma.conf.erb'),
        require => [
            Acme_chief::Cert['icinga'],
        ],
    }
}

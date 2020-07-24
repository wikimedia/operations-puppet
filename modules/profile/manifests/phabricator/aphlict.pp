# aphlict for phabricator
#
class profile::phabricator::aphlict (
    Stdlib::Unixpath $base_dir = lookup('aphlict_base_dir', { 'default_value' => '/srv/aphlict' }),
    Boolean $aphlict_ssl = lookup('phabricator_aphlict_enable_ssl', { 'default_value' => false }),
    Optional[Stdlib::Unixpath]  $aphlict_cert  = lookup('phabricator_aphlict_cert', { 'default_value' => undef }),
    Optional[Stdlib::Unixpath]  $aphlict_key   = lookup('phabricator_aphlict_key', { 'default_value' => undef }),
    Optional[Stdlib::Unixpath]  $aphlict_chain = lookup('phabricator_aphlict_chain', { 'default_value' => undef }),
    String $deploy_target = lookup('phabricator_deploy_target', { 'default_value' => 'phabricator/deployment'}),
    Optional[String] $deploy_user   = lookup('phabricator_deploy_user', { 'default_value' => 'phab-deploy' }),
    Boolean $manage_scap_user = lookup('profile::phabricator::main::manage_scap_user', { 'default_value' => true }),
) {

    $deploy_root = "/srv/deployment/${deploy_target}"

    class { '::phabricator::aphlict':
        ensure     => present,
        enable_ssl => $aphlict_ssl,
        sslcert    => $aphlict_cert,
        sslkey     => $aphlict_key,
        sslchain   => $aphlict_chain,
        basedir    => $base_dir,
    }

    ferm::service { 'notification_server':
        ensure => present,
        proto  => 'tcp',
        port   => '22280',
    }

    scap::target { $deploy_target:
        deploy_user => $deploy_user,
        key_name    => 'phabricator',
        manage_user => $manage_scap_user,
        sudo_rules  => [
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_promote',
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_rollback',
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_finalize',
        ],
    }

    file { $base_dir:
        ensure  => 'link',
        target  => $deploy_root,
        require => Package[$deploy_target],
    }
}

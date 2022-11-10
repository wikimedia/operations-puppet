# aphlict for phabricator
#
class profile::phabricator::aphlict (
    Wmflib::Ensure $ensure = lookup('profile::phabricator::aphlict::ensure', { 'default_value' => absent }),
    Stdlib::Unixpath $base_dir = lookup('aphlict_base_dir', { 'default_value' => '/srv/aphlict' }),
    Boolean $aphlict_ssl = lookup('phabricator_aphlict_enable_ssl', { 'default_value' => false }),
    Optional[Stdlib::Unixpath] $aphlict_cert  = lookup('phabricator_aphlict_cert', { 'default_value' => undef }),
    Optional[Stdlib::Unixpath] $aphlict_key   = lookup('phabricator_aphlict_key', { 'default_value' => undef }),
    Optional[Stdlib::Unixpath] $aphlict_chain = lookup('phabricator_aphlict_chain', { 'default_value' => undef }),
    String $deploy_target = lookup('phabricator_deploy_target', { 'default_value' => 'phabricator/deployment'}),
    Optional[String] $deploy_user = lookup('phabricator_deploy_user', { 'default_value' => 'phab-deploy' }),
    Boolean $manage_scap_user = lookup('profile::phabricator::main::manage_scap_user', { 'default_value' => true }),
    Optional[String] $phabricator_server = lookup('phabricator_server', { 'default_value' => undef }),
    Optional[Stdlib::Port] $client_port = lookup('profile::phabricator::aphlict::client_port', { 'default_value' => undef }),
    Optional[Stdlib::IP::Address] $client_listen = lookup('profile::phabricator::aphlict::client_listen', { 'default_value' => undef }),
    Optional[Stdlib::Port] $admin_port = lookup('profile::phabricator::aphlict::admin_port', { 'default_value' => undef }),
    Optional[Stdlib::IP::Address] $admin_listen = lookup('profile::phabricator::aphlict::admin_listen', { 'default_value' => undef }),
) {

    $deploy_root = "/srv/deployment/${deploy_target}"

    class { '::phabricator::aphlict':
        ensure        => $ensure,
        enable_ssl    => $aphlict_ssl,
        sslcert       => $aphlict_cert,
        sslkey        => $aphlict_key,
        sslchain      => $aphlict_chain,
        basedir       => $base_dir,
        client_port   => $client_port,
        client_listen => $client_listen,
        admin_port    => $admin_port,
        admin_listen  => $admin_listen,
    }

    ferm::service { 'notification_server':
        ensure => present,
        proto  => 'tcp',
        port   => $client_port,
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

    # needed by deployment scripts only
    ensure_packages('php-cli')

    # phabricator server needs to connect to the aphlict admin port
    ferm::service { 'phab_aphlict_admin_port':
        proto  => 'tcp',
        port   => "(${admin_port})",
        srange => "@resolve(${phabricator_server})",
    }
}

# SPDX-License-Identifier: Apache-2.0
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
    Optional[Stdlib::Host] $phabricator_active_server = lookup('phabricator_active_server', { 'default_value' => undef }),
    Optional[Stdlib::Port] $client_port = lookup('profile::phabricator::aphlict::client_port', { 'default_value' => undef }),
    Optional[Stdlib::IP::Address] $client_listen = lookup('profile::phabricator::aphlict::client_listen', { 'default_value' => undef }),
    Optional[Stdlib::Port] $admin_port = lookup('profile::phabricator::aphlict::admin_port', { 'default_value' => undef }),
    Optional[Stdlib::IP::Address] $admin_listen = lookup('profile::phabricator::aphlict::admin_listen', { 'default_value' => undef }),
    Boolean $puppet_managed_config = lookup('profile::phabricator::aphlict::puppet_controlled_phabricator_config', { 'default_value' => false }),
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

    $dummy_phab_config_deploy_vars = {
        'phabricator' => {
            'www'       => {
                'database_username' => '',
                'database_password' => '',
            },
            'mail'      => {
                'database_username' => '',
                'database_password' => '',
            },
            'phd'       => {
                'database_username' => '',
                'database_password' => '',
            },
            'vcs'       => {
                'database_username' => '',
                'database_password' => '',
            },
            'redirects' => {
                'database_username' => '',
                'database_password' => '',
                'database_host'     => '',
                'field_index'       => '',
            },
            'local'     => {
                'base_uri'                  => '',
                'alternate_file_domain'     => '',
                'mail_default_address'      => '',
                'mail_reply_handler_domain' => '',
                'phd_taskmasters'           => '',
                'ssh_host'                  => '',
                'notification_servers'      => '',
                'cluster_search'            => '',
                'cluster_mailers'           => '',
                'database_host'             => '',
                'database_port'             => '',
                'gitlab_api_key'            => '',
            },
        },
    }

    if $puppet_managed_config {
        class { '::phabricator::config':
            manage_scap_user   => $manage_scap_user,
            deploy_user        => $deploy_user,
            deploy_root        => $deploy_root,
            storage_user       => 'dummy_user',
            storage_pass       => 'dummy_pass',
            config_deploy_vars => $dummy_phab_config_deploy_vars,
        }
    } else {
        # This is managed in the phabricator::config class, so we can elide this if we're including that class
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
    }

    if $client_port {
        firewall::service { 'notification_server':
            ensure => present,
            proto  => 'tcp',
            port   => $client_port,
        }
    }

    file { $base_dir:
        ensure  => link,
        target  => $deploy_root,
        require => Package[$deploy_target],
    }

    # needed by deployment scripts only
    ensure_packages('php-cli')

    if $phabricator_active_server {
        # phabricator server needs to connect to the aphlict admin port
        firewall::service { 'phab_aphlict_admin_port':
            proto  => 'tcp',
            port   => $admin_port,
            srange => [$phabricator_active_server],
        }
    }
}

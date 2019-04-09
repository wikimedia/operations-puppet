# = Class: profile::yubiauth::server
#
# This class configures a Yubi 2FA authentication server
#
class profile::yubiauth::server (
    $auth_servers = hiera('yubiauth_servers'),
    $auth_server_primary = hiera('yubiauth_server_primary'),
    $bastion_hosts = hiera('bastion_hosts'),
) {

    include ::profile::base::firewall

    class {'::yubiauth::yhsm_daemon': }

    class {'::yubiauth::yhsm_yubikey_ksm': }

    backup::set { 'yubiauth-aeads' : }

    if ($::fqdn == $auth_server_primary) {

        class { 'yubiauth::yhsm_aead_sync':
            sync_allowed => $auth_servers,
        }
    }
    else {
        cron { 'sync AEAD files from primary auth server':
            command => "/usr/bin/rsync -az ${auth_server_primary}::aead_sync /var/cache/yubikey-ksm/aeads",
            user    => 'root',
            minute  => '*/30',
        }
    }

    $bastion_hosts_str = join($bastion_hosts, ' ')
    ferm::service { 'yubikey-validation-server':
        proto  => 'tcp',
        port   => '80',
        srange => "(${bastion_hosts_str})",
    }
}

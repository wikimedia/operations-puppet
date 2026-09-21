# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::etcd::backup (
    Array[Stdlib::Fqdn] $etcd_hosts = lookup('profile::wmcs::etcd::peer_hosts'),
) {
    ensure_packages([
        'etcd-client',
    ])

    wmflib::dir::mkdir_p('/srv/backup/etcd')

    file { '/usr/local/sbin/backup-etcd':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/profile/wmcs/etcd/backup/backup.sh',
    }

    $backup_env = {
        'ETCDCTL_VERSION'   => '3',
        'ETCDCTL_CERT'      => $facts['puppet_config']['hostcert'],
        'ETCDCTL_KEY'       => $facts['puppet_config']['hostprivkey'],
        'ETCDCTL_CACERT'    => profile::base::certificates::get_trusted_ca_path(),
        # etcd snapshots can only be taken from a single host.
        # they all contain the same data, so just arbitrarily pick the first.
        'ETCDCTL_ENDPOINTS' => "https://${etcd_hosts[0]}:2379",
    }

    systemd::timer::job { 'backup-etcd':
        ensure             => present,
        user               => 'root',
        description        => 'create a backup of the cloudinfra etcd database',
        command            => '/usr/local/sbin/backup-etcd',
        environment        => $backup_env,
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }
}

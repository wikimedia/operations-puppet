class swift::container_sync (
    $replication_accounts = $::swift::params::replication_accounts,
    $replication_keys     = $::swift::params::replication_keys,
) {
    file { '/etc/swift/container-sync-realms.conf':
        ensure    => present,
        mode      => '0440',
        owner     => 'swift',
        group     => 'swift',
        content   => template('swift/container-sync-realms.conf.erb'),
        show_diff => false,
    }
}

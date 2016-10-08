class swift::container_sync (
    $replication_accounts = {},
    $replication_keys     = {},
) {
    file { '/etc/swift/container-sync-realms.conf':
        ensure  => present,
        mode    => '0440',
        owner   => 'swift',
        group   => 'swift',
        content => template('swift/container-sync-realms.conf.erb'),
    }
}

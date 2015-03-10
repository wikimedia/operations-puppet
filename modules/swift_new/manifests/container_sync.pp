class swift_new::container_sync (
    $replication_accounts = $::swift_new::params::replication_accounts,
    $replication_keys     = $::swift_new::params::replication_keys,
) {
    file { '/etc/swift/container-sync-realms.conf':
        ensure  => present,
        mode    => '0440',
        owner   => 'swift',
        group   => 'swift',
        content => template('swift_new/container-sync-realms.conf.erb'),
    }
}

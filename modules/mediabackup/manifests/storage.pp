# Media backups storage: Install required packages and configures
# them.
class mediabackup::storage (
) {
    ensure_packages(['minio', ])

    service { 'minio':
        ensure  => running,
        enable  => true,
        require => Package['minio'],
    }
}

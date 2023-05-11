# Actual backup storage for media backups
class role::mediabackup::storage {
    system::role { 'mediabackup::storage':
        description => 'Media backups storage server',
    }

    include ::profile::base::production
    include ::profile::firewall

    include ::profile::mediabackup::storage
}

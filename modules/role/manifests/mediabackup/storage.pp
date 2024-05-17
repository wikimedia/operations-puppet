# Actual backup storage for media backups
class role::mediabackup::storage {
    include profile::base::production
    include profile::firewall

    include profile::mediabackup::storage
}

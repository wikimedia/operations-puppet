class releases::backups {
    include 'backup::host'
    backup::set { 'srv-org-wikimedia': }
}

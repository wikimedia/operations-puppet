class releases::backups {
    include role::backup::host
    backup::set { 'srv-org-wikimedia': }
}

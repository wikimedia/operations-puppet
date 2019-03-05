class role::wmcs::nfs::misc_backup {
    system::role { $name: }

    include ::standard
    include ::profile::base::firewall
    include ::profile::wmcs::nfs::ferm
    include ::profile::wmcs::nfs::monitoring::interfaces
    include ::profile::wmcs::nfs::misc_backup
}

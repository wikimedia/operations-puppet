class role::peek {
    system::role { 'peek': description => 'Security Team Tooling' }
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::peek
}

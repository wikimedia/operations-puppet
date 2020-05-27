class role::peek {
    system::role { 'peek': description => 'Security Team Tooling' }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::peek
}

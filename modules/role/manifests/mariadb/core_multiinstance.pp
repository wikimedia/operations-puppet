class role::mariadb::core_multiinstance {
    system::role { 'mariadb::core':
        description => 'Core multi-instance server',
    }
    # lint:ignore:wmf_styleguide
    include ::base::firewall
    # lint:endignore:wmf_styleguide
    include ::standard
    include ::profile::mariadb::core::multiinstance
}

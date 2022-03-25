class role::wmcs::paws::prometheus {
    system::role { 'wmcs::paws::prometheus': }

    include ::profile::wmcs::paws::common
    include ::profile::wmcs::paws::prometheus
}

class role::ml_serve {
    system::role { 'ml_serve':
        description => 'Machine Learning model serving cluster',
    }
    include ::profile::standard
    include ::profile::base::firewall
}

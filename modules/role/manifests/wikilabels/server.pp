class role::wikilabels::server {
    include profile::base::production
    include wikilabels::session

    class { '::profile::wikilabels':
        branch => 'deploy',
    }
}

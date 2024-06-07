class role::wikilabels::staging {
    include profile::base::production
    include wikilabels::session

    class { '::profile::wikilabels':
        branch => 'master',
    }
}

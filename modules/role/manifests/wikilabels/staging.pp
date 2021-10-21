# filtertags: labs-project-wikilabels
class role::wikilabels::staging {

    system::role { $name: }

    include ::profile::base::production
    include ::wikilabels::session

    class { '::profile::wikilabels':
        branch => 'master',
    }
}

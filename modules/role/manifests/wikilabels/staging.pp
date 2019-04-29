# filtertags: labs-project-wikilabels
class role::wikilabels::staging {

    system::role { $name: }

    include ::profile::standard
    include ::wikilabels::session

    class { '::profile::wikilabels':
        branch => 'master',
    }
}

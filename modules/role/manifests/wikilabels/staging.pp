# filtertags: labs-project-wikilabels
class role::wikilabels::staging {

    system::role { $name: }

    include ::wikilabels::session

    class { '::profile::wikilabels::server':
        branch = 'master',
    }
}

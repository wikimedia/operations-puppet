# filtertags: labs-project-wikilabels
class role::wikilabels::server {

    system::role { $name: }

    include ::wikilabels::session

    class { '::profile::wikilabels::server':
        branch => 'deploy',
    }
}

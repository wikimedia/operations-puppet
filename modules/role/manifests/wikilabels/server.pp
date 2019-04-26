# filtertags: labs-project-wikilabels
class role::wikilabels::server {

    system::role { $name: }

    include ::standard
    include ::wikilabels::session

    class { '::profile::wikilabels':
        branch => 'deploy',
    }
}

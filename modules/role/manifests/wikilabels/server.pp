# filtertags: labs-project-wikilabels
class role::wikilabels::server {
    class { 'wikilabels::web':
        branch => 'deploy',
    }

    include ::wikilabels::session

    class { '::wikilabels::db_proxy':
        server => 'pgsql.eqiad.wmnet',
    }
}

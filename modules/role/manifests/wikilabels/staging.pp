# filtertags: labs-project-wikilabels
class role::wikilabels::staging {
    class { 'wikilabels::web':
        branch => 'master',
    }

    include ::wikilabels::session

    class { '::wikilabels::db_proxy':
        server => 'pgsql.eqiad.wmnet',
    }
}

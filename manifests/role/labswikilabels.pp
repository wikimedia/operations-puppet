class role::labs::wikilabels::staging {
    class { 'wikilabels::web':
        branch => 'master',
    }

    include ::wikilabels::session

    class { '::wikilabels::db_proxy':
        server => 'pgsql.eqiad.wmnet',
    }
}

class role::labs::wikilabels {
    class { 'wikilabels::web':
        branch => 'deploy',
    }

    include ::wikilabels::session

    class { '::wikilabels::db_proxy':
        server => 'pgsql.eqiad.wmnet',
    }
}
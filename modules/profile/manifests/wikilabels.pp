class profile::wikilabels (
    $branch = undefined,
){

    class { 'wikilabels::web':
        branch => $branch,
    }

    class { '::wikilabels::db_proxy':
        server => 'wikilabels.db.svc.eqiad.wmflabs',
    }
}

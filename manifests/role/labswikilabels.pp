class role::labs::wikilabels::staging {
    class { 'wikilabels::web':
        branch => 'staging',
    }
    include ::wikilabels::db
    include ::wikilabels::session
}
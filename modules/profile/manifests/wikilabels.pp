class profile::wikilabels (
    $branch = undefined,
){
    class { 'wikilabels::web':
        branch => $branch,
    }
}

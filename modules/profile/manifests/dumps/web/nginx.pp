class profile::dumps::web::nginx {
    # includes module for bandwidth limits
    class { '::nginx':
        variant => 'extras',
    }
}

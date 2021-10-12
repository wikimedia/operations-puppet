class thanos {
    exec { 'reload thanos-rule':
        command     => '/bin/systemctl reload thanos-rule',
        refreshonly => true,
    }
}

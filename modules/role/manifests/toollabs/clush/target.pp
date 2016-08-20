class role::toollabs::clush::target(
    $master,
) {
    ::clush::target { 'clushuser':
        ensure => present,
    }

    security::access::config { 'clushuser':
        content => "+ : clushuser : ${master}\n",
    }
}

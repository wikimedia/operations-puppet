class role::toollabs::clush::target {
    ::clush::target { 'clushuser':
        ensure => present,
    }
}

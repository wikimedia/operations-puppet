class profile::beta::icu57 {
    if os_version('debian == jessie') {
        apt::repository { 'hhvm-icu57':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'jessie-wikimedia',
            components => 'component/icu57',
        }
    }
}

define install_additional_key(
    $key_loc = '',
    $owner   = 'root',
    $group   = 'ssl-cert',
    $mode    = '0440',
) {

    if ( $key_loc ) {
        file { "${key_loc}/${name}.key":
            owner   => $owner,
            group   => $group,
            mode    => $mode,
            source  => "puppet:///private/ssl/${name}.key",
            require => Package['openssl'],
        }
    }
}


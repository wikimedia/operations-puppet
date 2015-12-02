class role::mediawiki::scaler {
    include ::role::mediawiki::common
    include ::mediawiki::multimedia

    file { '/etc/wikimedia-scaler':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}


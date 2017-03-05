class mediawiki::maintenance::uploads( $ensure = present ) {
    file { '/etc/wgetrc':
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/mediawiki/maintenance/uploads/wgetrc',
    }
}


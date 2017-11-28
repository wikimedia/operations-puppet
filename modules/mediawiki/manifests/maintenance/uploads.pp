class mediawiki::maintenance::uploads( $ensure = present ) {
    file { '/etc/wgetrc':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mediawiki/maintenance/uploads/wgetrc.erb'),
    }
}


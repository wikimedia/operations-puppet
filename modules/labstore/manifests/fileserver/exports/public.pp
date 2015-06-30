class labstore::fileserver::exports::public {

    require ::labstore::fileserver::exports

    # This exports the global (non-project specific)
    # file systems to everyone.
    file { '/etc/exports.d/PUBLIC.exports':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/PUBLIC.exports',
        require => File['/etc/exports.d'],
    }
}

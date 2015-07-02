class labstore::fileserver::exports {
    group { 'nfsmanager':
        ensure => present,
        name   => 'nfsmanager',
        system => true,
    }

    user { 'nfsmanager':
        home       => '/var/lib/nfsmanager',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    file { '/etc/exports.d':
        ensure => directory,
        owner  => 'root',
        group  => 'nfsmanager',
        mode   => '2775',
    }

    # Base exports for the file service: the root (/exp) fs
    # unconditionnally as fsid 0 for the NFS4 export tree
    file { '/etc/exports.d/ROOT.exports':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/ROOT.exports',
        require => File['/etc/exports.d'],
    }
}

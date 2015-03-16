class security::pam {

    # We will not put pam-configs files directly in /usr/share because
    # otherwise removing the resource from puppet will actually cause
    # them to be lost track of, potentially creating security issues.
    # Instead, we fully manage the local directory and use symlinks
    # into it so that we can invoke pam-auth-update --remove as needed.

    # Because of the way puppet manages directories, we have no way
    # to hook to execute something before it deletes a no-longer
    # managed file, so what we do instead is maintain a "shadow"
    # copy of the file in a subdirectory (.installed) and run a
    # script over /it/ instead, executing pam-auth-update as
    # appropriate.

    file { '/usr/local/share/pam-configs':
        ensure       => directory,
        owner        => 'root',
        group        => 'root',
        mode         => '0755',
        recurse      => true,
        purge        => true,
        recurselimit => 1,
        notify       => Exec['update-pam-configs'],
    }

    file { '/usr/local/share/pam-configs/.installed':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/usr/local/share/pam-configs'],
    }

    file { '/usr/local/sbin/sync-pam-configs':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/security/sync-pam-configs',
    }

    exec { 'update-pam-configs':
        refreshonly => true,
        path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
        command     => '/usr/local/sbin/sync-pam-configs',
        require     => File['/usr/local/share/pam-configs', '/usr/local/sbin/sync-pam-configs'],
    }

}



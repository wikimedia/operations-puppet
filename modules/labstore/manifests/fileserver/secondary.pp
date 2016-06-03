class labstore::fileserver::secondary {

    requires_os('Debian >= jessie')

    include labstore

    package { [
            'python3-paramiko',
            'python3-pymysql',
        ]:
        ensure => present,
    }
}

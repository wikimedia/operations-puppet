class labstore::fileserver::secondary {

    requires_os('debian >= jessie')

    class {'::labstore':
        nfsd_threads => '300',
    }

    package { [
            'python3-paramiko',
            'python3-pymysql',
        ]:
        ensure => present,
    }
}

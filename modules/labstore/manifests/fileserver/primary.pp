class labstore::fileserver::primary {

    requires_os('Debian >= jessie')

    # Set to true only for the labstore that is currently
    # actively serving files
    $is_active = (hiera('active_labstore_host') == $::hostname)

    include ::labstore
    include ::labstore::fileserver::exports

    require_package('python3-paramiko')
    require_package('python3-pymysql')

    # There is no service {} stanza on purpose -- this service
    # must *only* be started by a manual operation because it must
    # run exactly once on whichever NFS server is the current
    # active one.

    file { '/usr/local/sbin/start-nfs':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/labstore/start-nfs',
    }
}

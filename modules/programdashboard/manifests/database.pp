# = Class: programdashboard::database
#
# A database server for the the Program Dashboard Rails application.
#
# === Parameters
#
# [*datadir*]
#   MariaDB data directory. An XFS formatted LVM volume will be created from
#   80% of the instance volume's free space and mounted at this directory.
#
# [*tmpdir*]
#   MariaDB temporary directory. An XFS formatted LVM volume will be created
#   from 20% of the instance volume's free space and mounted at this
#   directory.
#
class programdashboard::database(
    $datadir,
    $tmpdir,
) {
    include mariadb::packages

    labs_lvm::volume { 'dashboard-data':
        mountat => $datadir,
        size    => '80%FREE',
    }

    labs_lvm::volume { 'dashboard-tmp':
        mountat => $tmpdir,
        size    => '100%FREE',
        require => Labs_lvm::Volume['dashboard-data'],
    }

    class { 'mariadb::config':
        prompt   => 'DASHBOARD',
        config   => 'programdashboard/my.cnf.erb',
        datadir  => "${datadir}/sql",
        tmpdir   => "${tmpdir}/sql",
        require  => Labs_lvm::Volume['dashboard-data', 'dashboard-tmp'],
    }

    # Install mysql databases
    exec { 'initialize-programdashboard-db':
        command => '/usr/bin/mysql_install_db',
        creates => "${datadir}/mysql",
        require => Class['mariadb::config'],
        notify  => Exec['grant-root-peercred-auth'],
    }

    service { 'mysql':
        ensure  => 'running',
        require => 'initialize-programdashboard-db',
    }

    # Authenticate mysql using unix_socket (this is a lot safer/easier than
    # trying to securely manage the root database password in labs)
    $sql = "GRANT USAGE ON *.* TO 'root'@'localhost' IDENTIFIED VIA unix_socket;"
    exec { 'grant-root-peercred-auth':
        command     => "/usr/bin/mysql --password= <<< \"${sql}\"",
        refreshonly => true,
        require     => Service['mysql'],
    }
}

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
        require => Labs_lvm::Volume['dashboard-db'],
    }

    class { 'mariadb::config':
        prompt   => 'DASHBOARD',
        config   => 'programdashboard/my.cnf.erb',
        datadir  => $datadir,
        tmpdir   => $tmpdir,
        require  => Labs_lvm::Volume['dashboard-db', 'dashboard-tmp'],
    }
}

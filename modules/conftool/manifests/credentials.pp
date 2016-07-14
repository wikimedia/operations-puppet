# == Define conftool::credentials
#
# Creates the appropriate credentials file in the home
# directory of a user to allow him to use conftool in
# read/write mode
define conftool::credentials(
    $home="/home/${title}",
    $group=$title,
    ) {
    require ::conftool

    etcd::client::config { "${home}/.etcdrc":
        ensure   => present,
        owner    => $title,
        group    => $title,
        settings => {
            username => 'conftool',
            password => $::conftool::password,
        }
    }

}

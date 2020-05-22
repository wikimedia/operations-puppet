# == Define conftool::credentials
#
# Creates the appropriate credentials file in the home
# directory of a user to allow him to use conftool in
# read/write mode
define conftool::credentials(
    Stdlib::Unixpath $home="/home/${title}",
    String $group=$title,
    Optional[String] $conftool_cluster = undef,
    String $pw_seed = ''
) {
    require ::passwords::etcd
    $credentials = conftool::cluster_credentials('conftool', $::passwords::etcd::accounts['conftool'], $pw_seed, $conftool_cluster)

    etcd::client::config { "${home}/.etcdrc":
        ensure   => present,
        owner    => $title,
        group    => $group,
        settings => $credentials,
    }

}

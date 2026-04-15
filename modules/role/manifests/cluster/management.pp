# === Class role::cluster::management
#
# This class setup a host to be a cluster manager, including all the tools,
# automation and orchestration softwares, ACL and such.
#
class role::cluster::management {
    include profile::base::production
    include profile::firewall

    include profile::cumin::master
    include profile::ipmi::mgmt
    include profile::access_new_install
    include profile::conftool::client
    include profile::conftool::dbctl_client

    include profile::spicerack
    include profile::spicerack::reposync
    include profile::spicerack::cookbooks::production
    include profile::homer

    include profile::debdeploy
    include profile::httpbb
    include profile::pwstore

    include profile::mariadb::wmf_root_client
    include profile::dbbackups::transfer

    include profile::netops::ripeatlas::cli
    include profile::netops::netdev_intermediate_ca

    include profile::frtech::kafka_certificate

    include profile::kubernetes::kubeconfig::admin

    include profile::cluster::management::firmwares

    # Backup all of /srv, including deployment, homer and  pwstore
    # move to a corresponding profile if the other profiles are split away
    include profile::backup::host
    include profile::cluster::management::backup
}

# === Class role::cluster::management
#
# This class setup a host to be a cluster manager, including all the tools,
# automation and orchestration softwares, ACL and such.
#
class role::cluster::management {

    system::role { 'cluster-management':
        description => 'Cluster management',
    }

    include profile::standard
    include profile::base::firewall

    # Temporary hack; for now cumin2001 is kept as a DBA management host,
    # but Spicerack/Cumin/Homer should be run from cumin2002 to prevent
    # issues with the Homer repo sync
    # lint:ignore:wmf_styleguide
    unless $::fqdn == 'cumin2001.codfw.wmnet' {
        include profile::spicerack
        include profile::homer
    }
    # lint:endignore

    include profile::cumin::master
    include profile::ipmi::mgmt
    include profile::access_new_install
    include profile::conftool::client
    include profile::conftool::dbctl_client
    include profile::debdeploy
    include profile::httpbb
    include profile::pwstore

    include profile::mariadb::wmf_root_client
    include profile::dbbackups::transfer

    include profile::netops::ripeatlas::cli

    include profile::sre::os_updates
    include profile::sre::check_user

    # Backup all of /srv, including deployment, homer and  pwstore
    # move to a corresponding profile if the other profiles are split away
    include profile::backup::host
    include profile::cluster::management::backup
}

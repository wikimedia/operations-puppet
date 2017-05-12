# bastion host combined with install_server
class profile::bastionhost::install {

    include ::bastionhost
    include ::base::firewall

    backup::set {'home': }
}

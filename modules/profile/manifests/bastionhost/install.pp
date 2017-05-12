# bastion host combined with install_server
class profile::bastionhost::install {

    class { '::bastionhost': }
    include ::bastionhost
    backup::set {'home': }
}

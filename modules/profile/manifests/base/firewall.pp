# Temporary solution until someone has input about what to do with base::firewall
class profile::base::firewall {
    class { '::base::firewall': }
}

# "Compendium" class for nodes supporting various *oid services
# This class is an intermediate step to better design
class role::sca {
    include standard
    include base::firewall
    if $::realm == 'production' {
        include lvs::realserver
    }
}

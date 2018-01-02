# == class role::recursor
#
# Class for configuring production dns recursors that use
# both class role::dnsrecursor and role::ntp
class role::recursor {
    require role::dnsrecursor
    require role::ntp
}

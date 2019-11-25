# == class role::dnsbox
#
# Combo class for configuring production dnsN00x machines in a combined role
# using both role::dns::recursor and role::ntp
class role::dnsbox {
    require role::dns::recursor
    require role::ntp
}

# == Class role::ntp
#
# Ntp server role
class role::ntp {

    system::role { 'ntp': description => 'NTP server' }

    include ::standard::ntp
    include ::profile::ntp
}

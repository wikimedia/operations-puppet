# == Class role::wmcs::services::ntp
#
# Ntp server role, to be applied to a cloud instance
class role::wmcs::services::ntp {

    system::role { 'ntp': description => 'NTP server for WMCS' }

    include ::profile::wmcs::services::ntp
}

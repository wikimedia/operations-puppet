# === Class Standard::ntp
#
# Basic common definitons used for NTP service configuration.
class standard::ntp {
    include network::constants

    # ntp monitoring queries
    # TODO: Make this realm independent
    $monitoring_acl = $network::constants::special_hosts['production']['monitoring_hosts']
    # Required for race-free ntpd startup, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=436029 :
    require_package('lockfile-progs')
}

# === Class Standard::ntp
#
# Basic common definitons used for NTP service configuration.
class standard::ntp {
    include network::constants

    # These are our servers - they all peer to each other
    #   and sync to upstream NTP pool servers.
    $wmf_peers = {
        eqiad => [
            'chromium.wikimedia.org',     # eqiad recdns
            'hydrogen.wikimedia.org',     # eqiad recdns
        ],
        codfw => [
            'acamar.wikimedia.org',       # codfw recdns
            'achernar.wikimedia.org',     # codfw recdns
        ],
        esams => [
            'nescio.wikimedia.org',       # esams recdns
            'maerlant.wikimedia.org',     # esams recdns
        ],
        ulsfo => [
            'dns4001.wikimedia.org',
            'dns4002.wikimedia.org',
        ],
        eqsin => [
            'dns5001.wikimedia.org',
            'dns5002.wikimedia.org',
        ],
    }

    # ntp monitoring queries
    # TODO: Make this realm independent
    $monitoring_acl = $network::constants::special_hosts['production']['monitoring_hosts']
    # Required for race-free ntpd startup, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=436029 :
    require_package('lockfile-progs')
}

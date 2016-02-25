# === Class Standard::ntp
#
# Basic common definitons used for NTP service configuration.
class standard::ntp {
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
        ulsfo => [],
    }

    # neon for ntp monitoring queries
    $neon_acl = [
        '208.80.154.14 mask 255.255.255.255',
    ]

    # Required for race-free ntpd startup, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=436029 :
    require_package('lockfile-progs')
}

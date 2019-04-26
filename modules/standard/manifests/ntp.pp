# === Class Standard::ntp
#
# Basic common definitons used for NTP service configuration.
class standard::ntp {
    # Required for race-free ntpd startup, see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=436029 :
    require_package('lockfile-progs')
}

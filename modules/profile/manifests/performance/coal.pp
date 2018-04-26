# This profile installs coal, which is a utility built/maintained by
# the performance team in order to collect decent median values
# for incoming RUM performance data.
#
#   Contact: performance-team@wikimedia.org
#
# This profile gets included from profile::performance::site, which is included
# from role::graphite::primary
#
class profile::performance::coal() {
    # Additional vars have defaults set in modules/coal/web.pp
    class { '::coal::web': }
}
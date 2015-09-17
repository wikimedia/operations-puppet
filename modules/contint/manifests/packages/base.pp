# === Class contint::packages::base
#
# Basic utilites needed for all Jenkins slaves
#
class contint::packages::base {
    # Colordiff gives us nice coloring in Jenkins console whenever
    # it is used instead of the stock diff.
    package { 'colordiff':
        ensure => present,
    }
}

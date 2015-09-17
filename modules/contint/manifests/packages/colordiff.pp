# === Class contint::packages::colordiff
#
# Colordiff gives us nice coloring in Jenkins console whenever
# it is used instead of the stock diff.
#
class contint::packages::colordiff {
    package { 'colordiff':
        ensure => present,
    }
}

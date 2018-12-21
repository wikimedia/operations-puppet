# === Class contint::packages::base
#
# Basic utilites needed for all Jenkins slaves
#
class contint::packages::base {
    # Colordiff gives us nice coloring in Jenkins console whenever
    # it is used instead of the stock diff.
    #
    # XXX Still used by integration-zuul-layoutdiff
    #
    package { 'colordiff':
        ensure => present,
    }

    # frontend tests use curl to make http requests to mediawiki
    package { [
        'curl',
        ]:
        ensure => present,
    }
}

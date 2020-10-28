# == Class: phabricator::arcanist
#
# Installs the phabricator client, arcanist, from apt.
#
class phabricator::arcanist {
    ensure_packages('arcanist')
}

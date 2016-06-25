# == Class: phabricator::arcanist
#
# Installs the phabricator client, arcanist, from apt.
#
class phabricator::arcanist {
    require_package('arcanist')
}

# base class for wikidata, commons and other wikibase entity dumps
# this does not set up any dumps by itself
class snapshot::cron::wikibase(
    $user = undef,
    $group = undef,
)  {
    # common to all dumps of wikibase data, regardless of
    # project or format
    file { '/usr/local/bin/wikibasedumps-shared.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikibase/wikibasedumps-shared.sh',
    }

    # dump script for wikibase rdf output
    # to add a new project, add the projectname to the list in this
    # file, and add a script with the appropriate functions in
    # puppet:///modules/snapshot/cron/wikibase/<projectname>_rdf_functions.sh
    file { '/usr/local/bin/dumpwikibaserdf.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/wikibase/dumpwikibaserdf.sh',
    }

    # serdi for translating ttl to nt
    require_package('serdi')

    # dcat software setup and configuration for wikibase dumps, see
    # https://www.w3.org/TR/vocab-dcat/
    git::clone { 'DCAT-AP':
        ensure    => 'present', # Don't automatically update.
        directory => '/usr/local/share/dcat',
        origin    => 'https://gerrit.wikimedia.org/r/operations/dumps/dcat',
        branch    => 'master',
        owner     => $user,
        group     => $group,
    }
}

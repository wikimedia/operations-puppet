# clones mediawiki core at /a/mediawiki/core
# and ensures that it is at the latest revision.
# RT 2162
class statistics::mediawiki {
    require mediawiki::users::mwdeploy

    $statistics_mediawiki_directory = '/a/mediawiki/core'

    git::clone { 'statistics_mediawiki':
        ensure    => 'latest',
        directory => $statistics_mediawiki_directory,
        origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git',
        owner     => 'mwdeploy',
        group     => 'wikidev',
    }
}

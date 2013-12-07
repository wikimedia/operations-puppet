# wikistats - mediawiki statistics site
#
# this sets up a site with statistics about
# as many public mediawiki installs as possible
# not just WMF wikis, but any mediawiki
#
# this is http://wikistats.wmflabs.org and will likely
# forever stay a labs project but be semi production
# results from it are used for WMF projects since
#
# it started out as an external project to create
# wiki syntax tables for pages like "List of largest wikis"
# on meta and several similar ones for other projects
# not to be confused with stats.wm by analytics
class wikistats ( $wikistats_host, $wikistats_ssl_cert, $wikistats_ssl_key ) {

    systemuser { 'wikistatsuser':
        name   => 'wikistats',
        home   => '/usr/lib/wikistats',
        groups => [ 'wikistats' ],
    }

    class { 'wikistats::web':
        wikistats_host     => $wikistats_host,
        wikistats_ssl_cert => $wikistats_ssl_cert,
        wikistats_ssl_key  => $wikistats_ssl_key,
    }

    class { 'wikistats::updates': }

}


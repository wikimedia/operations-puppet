# == Class wikimetrics::web inherits wikimetrics
#
class wikimetrics::web
{
    Class['wikimetrics'] -> Class['wikimetrics::web']

    apache::mod { 'wsgi': }
    apache::mod { 'rewrite': }

    $docroot = "${::wikimetrics::path}/wikimetrics"
    # apache stuff
    apache::vhost { 'wikimetrics':
        port          => 80,
        docroot       => $docroot,
        servername    => $::wikimetrics::server_name,
        serveraliases => $::wikimetrics::server_aliases,
        serveradmin   => 'noc@wikimedia.org',
        priority      => 90,
        # Use our own vhost template instead of apache module's.
        template      => 'wikimetrics/wikimetrics.vhost.erb',
        require       => [
            Apache::Mod['wsgi'],
            Apache::Mod['rewrite'],
        ],
    }
}

# == Class wikimetrics::web inherits wikimetrics
#
class wikimetrics::web(
    $server_name,
    $flask_secret_key,
    # Google Auth
    $google_client_secret,
    $google_client_id,
    $google_client_email,
    $ssl_redirect           = true,
    $server_aliases         = [],
)

{
    Class['wikimetrics'] -> Class['wikimetrics::web']

    file { "${wikimetrics::config_directory}/web_config.yaml":
        content => template('wikimetrics/web_config.yaml.erb')
    }

    apache::mod { 'wsgi': }
    apache::mod { 'rewrite': }

    $docroot = "${wikimetrics::path}/wikimetrics"
    # apache stuff
    apache::vhost { 'wikimetrics':
        port          => 80,
        docroot       => $docroot,
        servername    => $server_name,
        serveraliases => $server_aliases,
        serveradmin   => 'noc@wikimedia.org',
        priority      => 90,
        # Use our own vhost template instead of apache module's.
        template      => 'wikimetrics/wikimetrics.vhost.erb',
        require       => [
            File["${wikimetrics::config_directory}/web_config.yaml"],
            Apache::Mod['wsgi'],
            Apache::Mod['rewrite'],
        ],
    }
}

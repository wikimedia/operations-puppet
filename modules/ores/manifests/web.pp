# = Class: ores::web
# Sets up a uwsgi based web server for ORES running python3
class ores::web(
    $branch = 'deploy',
) {
    class { 'ores::base':
        branch => $branch,
    }

    uwsgi::app { 'ores-web':
        settings => {
            uwsgi => {
                plugins     => 'python3',
                'wsgi-file' => "${config_path}/ores.wmflabs.org.wsgi",
                master      => true,
                chdir       => $config_path,
                http-socket => '0.0.0.0:8080',
                venv        => $venv_path,
                processes   => inline_template('<%= @processorcount.to_i * 4 %>'),
            }
        }
    }
}

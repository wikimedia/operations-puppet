# @summary class to install the puppet uploader
# @param ensure ensurable parameter
# @param app_dir location to install the flask app
# @param upload_dir location to store uploaded files
# @param max_content_length The maximum upload size
# @param realms a hash of realms and the ip addresses that are allowed to make submissions
class puppet_compiler::uploader (
    Wmflib::Ensure   $ensure             = 'present',
    Stdlib::Port     $port               = 8001,
    Stdlib::Unixpath $app_dir            = '/usr/local/share/pcc_uploader',
    Stdlib::Unixpath $upload_dir         = '/srv/pcc_uploader',
    String[1]        $web_user           = 'www-data',
    String[1]        $web_group          = 'www-data',
    Integer          $max_content_length = 16000000,  # 16MB
    Hash[String[1], Hash[Stdlib::Host, String[1]]] $realms = {}
) {
    $wsgi_file = "${app_dir}/wsgi.py"
    $config_file = "${app_dir}/pcc_uploader.json"
    $config = {
        'UPLOAD_FOLDER'      => $upload_dir,
        'MAX_CONTENT_LENGTH' => $max_content_length,
        'REALMS'             => $realms,
    }

    ensure_packages(['python3-flask', 'python3-magic', 'python3-pypuppetdb'])
    wmflib::dir::mkdir_p([$app_dir, $upload_dir])
    $realms.keys.each |$realm| {
        file { "${upload_dir}/${realm}":
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => $web_user,
            group  => $web_group,
        }
    }
    file { $config_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        content => $config.to_json,
        notify  => Uwsgi::App['pcc-uploader'],
    }
    file { $wsgi_file:
        ensure => stdlib::ensure($ensure, 'file'),
        source => 'puppet:///modules/puppet_compiler/pcc_uploader.py',
        notify => Uwsgi::App['pcc-uploader'],
    }
    uwsgi::app{'pcc-uploader':
        settings => {
            uwsgi => {
                'plugins'     => 'python3',
                'master'      => true,
                'socket'      => "127.0.0.1:${port}",
                'wsgi-file'   => $wsgi_file,
                'die-on-term' => true,
            }
        }
    }
    file {'/usr/local/sbin/pcc_facts_processor':
        ensure => stdlib::ensure($ensure, 'file'),
        source => 'puppet:///modules/puppet_compiler/pcc_facts_processor.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }
    systemd::timer::job { 'pcc_facts_processor':
        ensure      => $ensure,
        user        => 'jenkins-deploy',
        description => 'Process uploaded facts',
        command     => '/usr/local/sbin/pcc_facts_processor',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
    }
}

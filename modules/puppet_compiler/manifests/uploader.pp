# SPDX-License-Identifier: Apache-2.0
# @summary class to install the puppet uploader
# @param ensure ensurable parameter
# @param port the port the service listens on
# @param app_dir location to install the flask app
# @param upload_dir location to store uploaded files
# @param webroot the docuemtn root of the website
# @param jenkins_user user jenkis process uses
# @param jenkins_group group jenkis process uses
# @param web_user user web process uses
# @param web_group group web process uses
# @param max_content_length The maximum upload size
# @param realms a hash of realms and the ip addresses that are allowed to make submissions
class puppet_compiler::uploader (
    Wmflib::Ensure   $ensure             = 'present',
    Stdlib::Port     $port               = 8001,
    Stdlib::Unixpath $app_dir            = '/usr/local/share/pcc_uploader',
    Stdlib::Unixpath $upload_dir         = '/srv/pcc_uploader',
    Stdlib::Unixpath $webroot            = '/srv/www',
    String[1]        $jenkins_user       = 'jenkins-deploy',
    String[1]        $jenkins_group      = 'wikidev',
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
    wmflib::dir::mkdir_p([$app_dir, $upload_dir, $webroot])
    file { "${webroot}/facts":
        ensure => stdlib::ensure($ensure, 'directory'),
        mode   => '0660',
        owner  => $web_user,
        group  => $jenkins_group,
    }
    $realms.keys.each |$realm| {
        file { "${upload_dir}/${realm}":
            ensure => stdlib::ensure($ensure, 'directory'),
            owner  => $web_user,
            mode   => '0660',
            group  => $jenkins_group,
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
            },
        },
    }
    file {'/usr/local/sbin/pcc_facts_processor':
        ensure => stdlib::ensure($ensure, 'file'),
        source => 'puppet:///modules/puppet_compiler/pcc_facts_processor.py',
        owner  => 'root',
        group  => $jenkins_group,
        mode   => '0550',
    }
    systemd::timer::job { 'pcc_facts_processor':
        ensure      => $ensure,
        user        => $jenkins_user,
        description => 'Process uploaded facts',
        command     => '/usr/local/sbin/pcc_facts_processor',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
    }
}

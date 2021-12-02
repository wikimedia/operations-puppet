# @summary class to install the puppet uploader
# @param ensure ensurable parameter
# @param app_dir location to install the flask app
# @param upload_dir location to store uploaded files
# @param max_content_length The maximum upload size
class puppet_compiler::uploader (
    Wmflib::Ensure   $ensure             = 'present',
    Stdlib::Unixpath $app_dir            = '/usr/local/share/ppc_uploader',
    Stdlib::Unixpath $upload_dir         = '/srv/pcc_uploader',
    Integer          $max_content_length = 16000000,  # 16MB
) {
    ensure_packages(['python3-flask', 'python3-magic'])
    wmflib::dir::mkdir($app_dir, $upload_dir)
    $wsgi_file = "${app_dir}/wsgi.py"
    $config_file = "${app_dir}/pcc_uploader.settings"
    $config = {
        'UPLOAD_FOLDER' => $upload_dir,
        'MAX_CONTENT_LENGTH' => $max_content_length,
    }
    file { $config_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        content => $config.to_json,
    }
    file { $wsgi_file:
        ensure => stdlib::ensure($ensure, 'file'),
        source => 'puppet:///modules/puppet_compiler/pcc_uploader.py',
    }
    uwsgi::app{'pcc-uploader':
        settings => {
            uwsgi => {
                'plugins'     => 'python3',
                'master'      => true,
                'http-socket' => '127.0.0.1:8081',
                'wsgi-file'   => $wsgi_file,
                'die-on-term' => true,
            }
        }
    }
}

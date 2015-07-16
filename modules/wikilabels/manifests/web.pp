# = Class: wiklabels::web
# Sets up a uwsgi based web server for Wikilabels running python3
class wikilabels::web (
    $branch = 'deploy',
    $config_path = '/srv/wikilabels/config',
    $venv_path = '/srv/wikilabels/venv',
    $data_path = '/srv/wikilabels/data',
) {

    # Let's use a virtualenv for maximum flexibility - we can convert
    # this to deb packages in the future if needed. 
    # FIXME: Use debian packages for all the packages needing compilation
    ensure_package('virtualenv', 'python3-dev', 'libffi-dev', 'npm', 
        'g++', 'libmemcached-dev')

    # Wikilabels is a python3 application
    ensure_package('uwsgi-plugin-python3')

    uwsgi::app { 'wikilabels-web':
        settings => {
            uwsgi => {
                plugins     => 'python3',
                'wsgi-file' => "${config_path}/labels.wmflabs.org.wsgi",
                master      => true,
                chdir       => $config_path,
                http-socket => '0.0.0.0:8080',
                venv        => $venv_path,
                processes   => inline_template('<%= @processorcount.to_i * 4 %>'),
            }
        }
    }

    file { '/srv':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/srv/ores':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
        require => File['/srv'],
    }

    git::clone { 'wikilabels-wikimedia-config':
        origin    => 'https://github.com/wiki-ai/wikilabels-wikimedia-config.git',
        ensure    => present,
        directory => $config_path,
        branch    => $branch,
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/wikilabels'],
    }
}

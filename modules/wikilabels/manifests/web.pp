# = Class: wiklabels::web
# Sets up a uwsgi based web server for Wikilabels running python3
#
class wikilabels::web (
    $branch = 'deploy',
) {

    $venv_path = '/srv/wikilabels/venv'
    $config_path = '/srv/wikilabels/config'

    # Let's use a virtualenv for maximum flexibility - we can convert
    # this to deb packages in the future if needed.
    # FIXME: Use debian packages for all the packages needing compilation
    ensure_packages(['virtualenv', 'python3-dev', 'libffi-dev',
        'libpq-dev', 'g++', 'libmemcached-dev'])

    # Wikilabels is a python3 application
    ensure_packages(['uwsgi-plugin-python3'])

    file { '/srv':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/srv/wikilabels':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
        require => File['/srv'],
    }

    git::clone { 'wikilabels-wikimedia-config':
        ensure    => present,
        origin    => 'https://github.com/wiki-ai/wikilabels-wikimedia-config.git',
        directory => $config_path,
        branch    => $branch,
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/wikilabels'],
    }

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
}

# = Class: ores::web
# Sets up a uwsgi based web server for ORES
class ores::web {
    require_package('python-virtualenv')

    require_package('python3-scipy')

    $src_path = '/srv/ores/src'
    $venv_path = '/srv/ores/venv'

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

    git::clone { 'ores-src':
        origin    => 'https://github.com/halfak/Objective-Revision-Evaluation-Service.git',
        directory => $src_path,
        branch    => 'deploy',
        ensure    => 'latest',
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/ores'],
    }

    exec { 'initial-setup-virtualenv':
        command => "/bin/mkdir -p ${venv_path} && /usr/bin/virtualenv --python python3 --system-site-packages ${venv_path}",
        user    => 'www-data',
        group   => 'www-data',
        creates => $venv_path,
        require   => File['/srv/ores'],
    }

    uwsgi::app { 'ores-web':
        settings => {
            uwsgi => {
                plugins     => 'python',
                protocol    => 'uwsgi',
                'wsgi-file' => "${src_path}/ores.wsgi",
                master      => true,
                chdir       => $src_path,
                socket      => '0.0.0.0:8080',
                venv        => '/srv/ores/venv',
            }
        }
    }
}

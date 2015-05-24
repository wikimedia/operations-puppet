# = Class: ores::web
# Sets up a uwsgi based web server for ORES
class ores::web {
    require_package('python3-virtualenv')

    $src_path = '/srv/ores/src'
    $venv_path = '/srv/ores/venv'

    file { '/srv':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/srv/ores':
        ensure  => present,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
        require => File['/srv'],
    }

    git::clone { 'https://github.com/halfak/Objective-Revision-Evaluation-Service.git':
        directory => $src_path,
        branch    => present,
        ensure    => 'latest',
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/ores'],
    }

    exec { 'initial-setup-virtualenv':
        command => "/usr/bin/virtualenv --python python3 ${venv_path}",
        user    => 'www-data',
        group   => 'www-data',
        creates => $venv_path,
        require   => File['/srv/ores'],
    }

    uwsgi::app { 'ores-web':
        settings        => {
            plugins     => 'python',
            protocol    => 'uwsgi',
            'wsgi-file' => "${clone_path}/ores.wsgi",
            master      => true,
            chdir       => $clone_path,
            socket      => '0.0.0.0:8080',
            venv        => '/srv/ores/venv',
        }
    }
}

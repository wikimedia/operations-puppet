# = Class: ores::web
# Sets up a uwsgi based web server for ORES running python3
class ores::web {
    # Let's use a virtualenv for maximum flexibility - we can convert
    # this to deb packages in the future if needed. We also install build tools
    # because they are needed by pip to install numpy, scipy and scilearn.
    # FIXME: Use debian packages for all the packages needing compilation
    require_package('python-virtualenv', 'python3-dev', 'build-essential',
                    'gfortran', 'libopenblas-dev', 'liblapack-dev')

    require_package('uwsgi-plugin-python3')

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
        command => "/bin/mkdir -p ${venv_path} && /usr/bin/virtualenv --python python3 ${venv_path}",
        user    => 'www-data',
        group   => 'www-data',
        creates => $venv_path,
        require   => File['/srv/ores'],
    }

    uwsgi::app { 'ores-web':
        settings => {
            uwsgi => {
                plugins   => 'python3',
                protocol  => 'uwsgi',
                module    => 'ores.wsgi.application:application',
                master    => true,
                chdir     => $src_path,
                socket    => '0.0.0.0:8080',
                venv      => '/srv/ores/venv',
                processes => inline_template('@phyiscalcorecount.to_i * 2'),
            }
        }
    }
}

# == Class: recommendation_api
#
# The Wikimedia Recommendation API is a JSON API that provides personalized
# recommendations of wiki content (to discover, edit, translate, etc.).
# It is a Flask webapp running under uWSGI.
#
# See <https://meta.wikimedia.org/wiki/Recommendation_API> for more info.
#
class recommendation_api {
    requires_os('debian >= jessie')

    require_package(
        'python3-bs4',
        'python3-dateutil',
        'python3-flask',
        'python3-numpy',
        'python3-pip',
        'python3-requests',
        'python3-simplejson',
        'python3-wheel',
        'python3-yaml',
    )

    $base_dir   = '/srv/recommendation-api'  # top-level dir for app
    $core_dir   = "${base_dir}/core"         # source code
    $wheels_dir = "${base_dir}/wheels"       # *.whl files
    $lib_dir    = "${base_dir}/lib"          # dependencies (installed from *.whl)

    file { [ $base_dir, $lib_dir ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'research/recommendation-api/wheels':
        ensure    => 'latest',
        directory => $wheels_dir,
        branch    => 'master',
    }

    git::clone { 'research/recommendation-api':
        ensure    => 'latest',
        directory => $core_dir,
        branch    => 'master',
    }

    exec { 'pip_install_wheels':
        command     => "/usr/bin/pip3 install --target=${lib_dir} --no-deps ${wheels_dir}/wheels/*.whl",
        require     => File[$lib_dir],
        user        => 'root',
        group       => 'root',
        subscribe   => Git::Clone['research/recommendation-api/wheels'],
        refreshonly => true,
    }

    uwsgi::app { 'recommendation_api':
        settings => {
            uwsgi => {
                'plugin'      => 'python3',
                'wsgi-file'   => "${core_dir}/recommendation/data/recommendation.wsgi",
                'master'      => true,
                'chdir'       => $core_dir,
                'http-socket' => '0.0.0.0:8080',
                'socket'      => '/run/uwsgi/recommendation_api.sock',
                'pythonpath'  => $lib_dir,
                'processes'   => inline_template('<%= @processorcount.to_i %>'),
            },
        },
        require  => [
            Exec['pip_install_wheels'],
            Git::Clone['research/recommendation-api'],
        ],
    }
}

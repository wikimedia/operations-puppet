# == Class: recommendation_api
#
class recommendation_api {
    require_package(
        'python3-flask',
        'python3-numpy',
        'python3-requests',
        'python3-yaml',
    )

    scap::target { 'research/recommendation-api':
        service_name => 'recommendation-api',
        deploy_user  => 'deploy-service',
        manage_user  => true,
    }

    uwsgi::app { 'recommendation_api':
        settings => {
            uwsgi => {
                plugins     => 'python',
                'wsgi-file' => 'fix/me.py',
                callable    => 'app',
                master      => true,
                chdir       => 'source/path/fixme',
                http-socket => '0.0.0.0:8080',
                venv        => 'venv/path/fixme',
                processes   => inline_template('<%= @processorcount.to_i %>'),
            }
        }
    }
}

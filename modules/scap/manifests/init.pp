# == Class scap
#
# Common role for scap masters and targets

class scap ($deployment_server = 'deployment') {

    package { 'scap':
        ensure => '3.2.0-1',
    }

    file { '/etc/scap.cfg':
        content => template('scap/scap.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    require_package([
        'python-psutil',
        'python-netifaces',
        'python-yaml',
        'python-requests',
        'python-jinja2',
    ])
}

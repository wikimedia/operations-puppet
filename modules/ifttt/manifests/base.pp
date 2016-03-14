# = Class: ifttt::base
# Base class that sets up directories and git repo
class ifttt::base(
    $branch = 'master',
    $venv_path = '/srv/ifttt/venv',
) {
    # Let's use a virtualenv for maximum flexibility - we can convert
    # the pip requirements to deb packages in the future if needed.
    ensure_packages(['virtualenv', 'gcc', 'python-dev', 'libmysqlclient-dev', 'libxml2-dev', 'libxslt1-dev'])

    $source_path = '/srv/ifttt'

    file { '/srv':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { $source_path:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0775',
        require => File['/srv'],
    }

    git::clone { 'ifttt':
        ensure    => present,
        origin    => 'https://github.com/madhuvishy/ifttt.git',
        directory => $source_path,
        branch    => $branch,
        owner     => 'www-data',
        group     => 'www-data',
        require   => File[$source_path],
    }
}

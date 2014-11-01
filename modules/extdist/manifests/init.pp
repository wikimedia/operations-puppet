# = Class: role::labs::extdist
#
# This class sets up a tarball generator for the Extension Distributor
# extension enabled on mediawiki.org.
#
class extdist(
    $base_dir = '/srv',
    $log_path = '/var/log/extdist') {

    $dist_dir = "${base_dir}/dist"
    $clone_dir = "${base_dir}/extdist"
    $src_path = "${base_dir}/src"
    $pid_folder = '/run/extdist'

    $settings = {
        'API_URL'   => 'https://www.mediawiki.org/w/api.php',
        'DIST_PATH' => $dist_dir,
        'GIT_URL'   => 'https://gerrit.wikimedia.org/r/mediawiki/extensions/%s',
        'LOG_FILE'  => $log_path,
        'SRC_PATH'  => $src_path,
        'PID_FILE'  => "${pid_folder}/pid.lock"
    }

    user { 'extdist':
        ensure => present,
        system => true,
    }

    file { '/home/extdist':
        ensure  => directory,
        owner   => 'extdist',
        require => User['extdist']
    }

    file { $log_path:
        ensure  => present,
        owner   => 'extdist',
        group   => 'www-data',
        require => User['extdist']
    }

    file { [$dist_dir, $clone_dir, $src_path, $pid_folder]:
        ensure => directory,
        owner  => 'extdist',
        group  => 'www-data',
        mode   => '0755',
    }

    git::clone {'labs/tools/extdist':
        ensure    => latest,
        directory => $clone_dir,
        branch    => 'master',
        require   => [File[$clone_dir], User['extdist']],
        owner     => 'extdist',
        group     => 'extdist',
    }

    file { '/etc/extdist.conf':
        ensure  => present,
        content => ordered_json($settings),
        owner   => 'extdist',
        require => User['extdist']
    }

    cron { 'extdist-generate-tarballs':
        command => "/usr/bin/python ${clone_dir}/nightly.py --all",
        user    => 'extdist',
        minute  => '0',
        hour    => '*',
        require => [
            Git::Clone['labs/tools/extdist'],
            User['extdist'],
            File['/etc/extdist.conf']
        ]
    }

    nginx::site { 'extdist':
        content => template('extdist/extdist.nginx.erb'),
    }
}

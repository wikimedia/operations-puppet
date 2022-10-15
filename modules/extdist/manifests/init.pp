# = Class: role::extdist
#
# This class sets up a tarball generator for the Extension Distributor
# extension enabled on mediawiki.org.
#
class extdist(
    Stdlib::Unixpath $base_dir = '/srv',
    Stdlib::Unixpath $log_dir  = '/var/log/'
) {
    $dist_dir   = "${base_dir}/dist"
    $clone_dir  = "${base_dir}/extdist"
    $src_path   = "${base_dir}/src"
    $pid_folder = '/run/extdist'

    ensure_packages(['python3-requests', 'php-cli', 'unzip', 'composer'])

    $ext_settings = {
        'API_URL'   => 'https://www.mediawiki.org/w/api.php',
        'GIT_URL'   => 'https://gerrit-replica.wikimedia.org/r/mediawiki/extensions/%s',
        'DIST_PATH' => "${dist_dir}/extensions",
        'LOG_FILE'  => "${log_dir}/extdist",
        'SRC_PATH'  => $src_path,
        'PID_FILE'  => "${pid_folder}/pid.lock",
        'COMPOSER'  => '/usr/bin/composer',
    }

    $skin_settings = {
        'API_URL'   => 'https://www.mediawiki.org/w/api.php',
        'DIST_PATH' => "${dist_dir}/skins",
        'GIT_URL'   => 'https://gerrit-replica.wikimedia.org/r/mediawiki/skins/%s',
        'LOG_FILE'  => "${log_dir}/skindist",
        'SRC_PATH'  => $src_path,
        'PID_FILE'  => "${pid_folder}/skinpid.lock",
        'COMPOSER'  => '/usr/bin/composer',
    }

    user { 'extdist':
        ensure => present,
        system => true,
    }

    file { '/home/extdist':
        ensure  => directory,
        owner   => 'extdist',
        require => User['extdist'],
    }

    file { [$dist_dir, $clone_dir, $src_path,
            $pid_folder, $log_dir]:
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
        content => to_json_pretty($ext_settings),
        owner   => 'extdist',
        require => User['extdist'],
    }

    file { '/etc/skindist.conf':
        ensure  => present,
        content => to_json_pretty($skin_settings),
        owner   => 'extdist',
        require => User['extdist'],
    }

    systemd::timer::job { 'extdist-generate-tarballs':
        ensure      => present,
        description => 'Regular jobs to generate extdist tarballs',
        user        => 'extdist',
        command     => "/usr/bin/python3 ${clone_dir}/nightly.py --all",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:00:00'},
        require     => [
            Git::Clone['labs/tools/extdist'],
            User['extdist'],
            File['/etc/extdist.conf'],
        ],
    }

    systemd::timer::job { 'skindist-generate-tarballs':
        ensure      => present,
        description => 'Regular jobs to generate skindist tarballs',
        user        => 'extdist',
        command     => "/usr/bin/python3 ${clone_dir}/nightly.py --all --skins",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:30:00'},
        require     => [
            Git::Clone['labs/tools/extdist'],
            User['extdist'],
            File['/etc/skindist.conf'],
        ],
    }

    nginx::site { 'extdist':
        content => template('extdist/extdist.nginx.erb'),
    }
}

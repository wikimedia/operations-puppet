# = Class: role::labs::extdist
#
# This class sets up a tarball generator for the Extension Distributor
# extension enabled on mediawiki.org.
#
class extdist(
    $base_dir = '/srv',
    $log_dir = '/var/log/'
){
    $dist_dir     = "${base_dir}/dist"
    $clone_dir    = "${base_dir}/extdist"
    $src_path     = "${base_dir}/src"
    $composer_dir = "${base_dir}/composer"
    $pid_folder   = '/run/extdist'

    $ext_settings = {
        'API_URL'   => 'https://www.mediawiki.org/w/api.php',
        'GIT_URL'   => 'https://gerrit.wikimedia.org/r/mediawiki/extensions/%s',
        'DIST_PATH' => "${dist_dir}/extensions",
        'LOG_FILE'  => "${log_dir}/extdist",
        'SRC_PATH'  => $src_path,
        'PID_FILE'  => "${pid_folder}/pid.lock",
        'COMPOSER'  => "${composer_dir}/vendor/bin/composer"
    }

    $skin_settings = {
        'API_URL'   => 'https://www.mediawiki.org/w/api.php',
        'DIST_PATH' => "${dist_dir}/skins",
        'GIT_URL'   => 'https://gerrit.wikimedia.org/r/mediawiki/skins/%s',
        'LOG_FILE'  => "${log_dir}/skindist",
        'SRC_PATH'  => $src_path,
        'PID_FILE'  => "${pid_folder}/skinpid.lock",
        'COMPOSER'  => "${composer_dir}/vendor/bin/composer"
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

    file { [$dist_dir, $clone_dir, $src_path,
            $pid_folder, $composer_dir, $log_dir]:
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

    package { 'php5-cli':
        ensure => present,
    }

    git::clone { 'integration/composer':
        ensure             => latest,
        directory          => $composer_dir,
        branch             => 'master',
        require            => [File[$composer_dir], User['extdist'], Package['php5-cli']],
        recurse_submodules => true,
        owner              => 'extdist',
        group              => 'extdist',
    }

    file { '/etc/extdist.conf':
        ensure  => present,
        content => ordered_json($ext_settings),
        owner   => 'extdist',
        require => User['extdist']
    }

    file { '/etc/skindist.conf':
        ensure  => present,
        content => ordered_json($skin_settings),
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

    cron { 'skindist-generate-tarballs':
        command => "/usr/bin/python ${clone_dir}/nightly.py --all --skins",
        user    => 'extdist',
        minute  => '30',
        hour    => '*',
        require => [
            Git::Clone['labs/tools/extdist'],
            User['extdist'],
            File['/etc/skindist.conf']
        ]
    }

    nginx::site { 'extdist':
        content => template('extdist/extdist.nginx.erb'),
    }
}

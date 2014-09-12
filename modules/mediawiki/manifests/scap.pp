class mediawiki::scap {
    include ::mediawiki::users

    $mediawiki_deployment_dir = '/srv/mediawiki'
    $mediawiki_staging_dir    = '/srv/mediawiki-staging'
    $scap_bin_dir             = '/srv/deployment/scap/scap/bin'

    package { 'scap':
        ensure   => latest,
        provider => 'trebuchet',
    }

    file { $mediawiki_deployment_dir:
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0775',
    }

    file { '/etc/profile.d/mediawiki.sh':
        content => template('mediawiki/mediawiki.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    exec { 'fetch_mediawiki':
        command => "${scap_bin_dir}/sync-common",
        creates => "${mediawiki_deployment_dir}/docroot",
        require => [ File[$mediawiki_deployment_dir], Package['scap'] ],
        timeout => 30 * 60,  # 30 minutes
    }
}

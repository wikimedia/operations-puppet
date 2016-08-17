# == Class: pdfrender
#
# This module installs and configures the PDF rendering service - a HTML2PDF
# conversion service based on the Electron framework.
#
# === Parameters
#
# [*width*]
#   The default browser width to use when converting, if not specified in the
#   request. Default: 1024
#
# [*height*]
#   The default browser height to use when converting, if not specified in the
#   request. Default: 768
#
# [*no_browsers*]
#   The number of browser instances to launch in parallel. Default: 1
#
# [*timeout*]
#   The maximum number of seconds to wait for a render to complete before
#   aborting it, in seconds. Default: 60
#
class pdfrender(
    $width       = 1024,
    $height      = 768,
    $no_browsers = 1,
    $timeout     = 60,
) {

    require ::mediawiki::packages::fonts
    include ::service::configuration

    $access_key = $::service::configuration::pdfrender_key
    $log_dir = "${::service::configuration::log_dir}/pdfrender"
    $home_dir = '/home/pdfrender'

    require_package('xvfb', 'xauth', 'firejail', 'nodejs', 'nodejs-legacy',
        'libxss1', 'xpra')

    monitoring::service { 'pdfrender':
        description   => 'pdfrender',
        check_command => 'check_http_on_port!5252',
    }

    scap::target { 'electron-render/deploy':
        deploy_user  => 'deploy-service',
        service_name => 'pdfrender',
        before       => Base::Service_unit['pdfrender'],
    }

    file { $home_dir:
        ensure => directory,
        owner  => 'pdfrender',
        group  => 'pdfrender',
        mode   => '0755',
        before => Base::Service_unit['pdfrender'],
    }

    group { 'pdfrender':
        ensure => present,
        system => true,
        before => User['pdfrender'],
    }

    user { 'pdfrender':
        gid    => 'pdfrender',
        home   => $home_dir,
        shell  => '/bin/bash',
        system => true,
        before => Base::Service_unit['pdfrender'],
    }

    file { $log_dir:
        ensure => directory,
        owner  => 'pdfrender',
        group  => 'pdfrender',
        mode   => '0755',
        before => Base::Service_unit['pdfrender'],
    }

    file { '/etc/firejail/pdfrender.profile':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/pdfrender/firejail.profile',
        before => Base::Service_unit['pdfrender'],
    }

    file { '/etc/xpra/xpra.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/pdfrender/xpra.conf',
        before => Base::Service_unit['pdfrender'],
    }

    systemd::syslog { 'pdfrender':
        readable_by => 'all',
        base_dir    => $::service::configuration::log_dir,
        group       => 'root',
        before      => Base::Service_unit['pdfrender'],
    }

    base::service_unit { 'pdfrender':
        ensure  => present,
        systemd => true,
    }

}

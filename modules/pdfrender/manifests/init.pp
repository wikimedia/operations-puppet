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

    include ::service::configuration

    $access_key = $::service::configuration::pdfrender_key
    $log_dir = "${::service::configuration::log_dir}/pdfrender"

    # TODO: revisit this list
    require_package('xvfb', 'libgtk2.0-0', 'ttf-mscorefonts-installer',
        'libnotify4', 'libgconf2-4', 'libxss1', 'libnss3', 'dbus-x11',
        'xauth', 'libXtst6', 'firejail', 'nodejs', 'nodejs-legacy')

    ferm::service { 'pdfrender_http_5252':
        proto => 'tcp',
        port  => '5252',
    }

    monitoring::service { 'pdfrender':
        description   => 'pdfrender',
        check_command => 'check_http_zotero!5252',
    }

    scap::target { 'electron-render/deploy':
        deploy_user  => 'deploy-service',
        service_name => 'pdfrender',
        before       => Base::Service_unit['pdfrender'],
    }

    group { 'pdfrender':
        ensure => present,
        system => true,
        before => User['pdfrender'],
    }

    user { 'pdfrender':
        gid    => 'pdfrender',
        home   => '/var/lib/pdfrender',
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

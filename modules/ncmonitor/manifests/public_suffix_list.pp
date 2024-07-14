# SPDX-License-Identifier: Apache-2.0
# @summary Install public suffix list data file and automatically update.
# @param ensure Configure with all files and services or remove/disable them.
# @param suffix_list_url Remote URL with which to fetch the data file.
# @param suffix_list_dir Destination directory to install the suffix file.
# @param suffix_file_name File name of the data file.
# @param http_proxy Proxy server to use for http/https outbound traffic.

class ncmonitor::public_suffix_list (
    Wmflib::Ensure            $ensure           = 'present',
    Stdlib::HTTPUrl           $suffix_list_url  = 'https://publicsuffix.org/list/public_suffix_list.dat',
    Stdlib::Absolutepath      $suffix_list_dir  = '/var/lib/ncmonitor',
    String                    $suffix_file_name = 'public_suffix_list.dat',
    Optional[Stdlib::HTTPUrl] $http_proxy       = undef,
){
    file { $suffix_list_dir:
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => 'ncmonitor',
        group  => 'root',
        mode   => '0755',
    }

    $suffix_list_abs_path = Stdlib::AbsolutePath("${suffix_list_dir}/${suffix_file_name}")
    file {'/usr/local/bin/ncmonitor-update-psl':
        ensure  => stdlib::ensure($ensure, 'file'),
        content => template('ncmonitor/ncmonitor-update-psl.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    systemd::unit { 'ncmonitor-update-psl.service':
        ensure  => $ensure,
        content => template('ncmonitor/ncmonitor-update-psl.service.erb'),
    }

    systemd::timer { 'ncmonitor-update-psl':
        ensure          => $ensure,
        timer_intervals => [
            {
                'start'    => 'OnCalendar',
                'interval' => 'weekly',
            }
        ]
    }
}

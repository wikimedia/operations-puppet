# Licence AGPL version 3 or later
#
# @author Addshore
#
# Related task: https://phabricator.wikimedia.org/T171258
#
# == Parameters
#   dir           - string. Directory to use.
#   user          - string. User to use.
class statistics::wmde::wdcm(
    $dir,
    $user  = 'analytics-wmde'
) {

    $src_dir  = "${dir}/src"

    file { $dir:
        ensure  => 'directory',
        owner   => $user,
        group   => $user,
        mode    => '0644',
        require => User[$user],
    }

    class { 'r_lang':
        devtools => false,
    }

    $cran_packages = [
        # Needed by wmde/WDCM scripts:
        # - WDCM_Sqoop_Clients.R
        # - WDCM_Search_Clients.R
        # - WDCM_Pre-Process.R
        'httr',
        'stringr',
        'XML',
        'readr',
        'data.table',
        'tidyr',
        'maptpx',
        'Rtsne',
        'proxy',
        'dplyr',
        'htmltab',
        'snowfall'
    ]

    r_lang::cran { $cran_packages:
        mirror => 'https://cran.cnr.berkeley.edu',
    }

    git::clone { 'wmde/WDCM':
        # TODO do we want a similar latest & production branch here? Or just manually pulling? scap?
        # Currently when we update the code in the repo we will have to pull the updates ourselves.
        ensure    => 'present',
        branch    => 'master',
        directory => $src_dir,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wmde/WDCM',
        owner     => $user,
        group     => $user,
        require   => File[$dir],
    }

}

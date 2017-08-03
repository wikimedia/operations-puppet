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

    git::clone { 'analytics/wmde/WDCM':
        # TODO do we want a similar latest & production branch here? Or just manually pulling? scap?
        # Currently when we update the code in the repo we will have to pull the updates ourselves.
        ensure    => 'present',
        branch    => 'master',
        directory => $src_dir,
        owner     => $user,
        group     => $user,
        require   => File[$dir],
    }

    # TODO the scripts in the WDCM repo require R, but apparently we can't specify that here without things breaking.

    # TODO we also can't yes install any R packages that we require, but we work around that by using a maanual script.
    # The WDCM repo has a script _installProduction_analytics-wmde.R which can be used to install the libraries needed.
    # https://phabricator.wikimedia.org/T170995

    # TODO crons for the R scripts will live here once each script is ready for production.

}

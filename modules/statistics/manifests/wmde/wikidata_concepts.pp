# Licence AGPL version 3 or later
#
# @author Addshore
#
# Related task: https://phabricator.wikimedia.org/T171258
#
# == Parameters
#   dir           - string. Directory to use.
#   user          - string. User to use.
class statistics::wmde::wikidata_concepts(
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

    git::clone { 'wmde/WDCM':
        # TODO do we want a similar latest & production branch here? Or just manually pulling? scap?
        ensure    => 'present',
        branch    => 'master',
        directory => $src_dir,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wmde/WDCM',
        owner     => $user,
        group     => $user,
        require   => File[$dir],
    }

}

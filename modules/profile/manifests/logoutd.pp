# @summary this class provides scaffolding for logoutd
#   A cli based API for deleting user sessions
# @param owner the owner of the scripts
# @param group the group of the scripts
# @param scripts A hash of profile::logoutd::scripts to install
class profile::logoutd (
    String $owner   = lookup('profile::logoutd::owner'),
    String $group   = lookup('profile::logoutd::group'),
    Hash   $scripts = lookup('profile::logoutd::scripts'),
) {
    $base_dir = '/etc/wikimedia/logout.d'
    wmflib::dir::mkdir_p($base_dir, {
        owner  => $owner,
        group  => $group,
        mode   => '0550',
        source => 'puppet:///modules/profile/logout.d',
    })
    file {'/usr/local/sbin/wmf-run-logout-scripts':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/profile/logoutd/wmf_run_logout_scripts.py',
    }
    $scripts.each |$res_title, $params| {
        profile::logoutd::script { $res_title:
            * => $params,
        }
    }
}

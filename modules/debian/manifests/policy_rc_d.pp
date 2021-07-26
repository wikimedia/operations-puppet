# @summary this class is used to install a custom policy-rd.d script.  The script
# is used by debian::autostart to prevent daemons from starting on installation
class debian::policy_rc_d {
    $policy_rd_d_dir = '/etc/wikimedia/policy-rc.d'
    wmflib::dir::mkdir_p($policy_rd_d_dir, {
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        purge   => true,
        recurse => true,
    })

    file {'/usr/sbin/policy-rc.d':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/debian/policy_rc_d.py',
    }
}

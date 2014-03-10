# Definition: bacula::director::pool
#
# This definition creates a bacula director pool definition
#
# Parameters:
#   $max_vols
#       The max number of volumes in this pool
#   $max_vol_bytes
#       The size of each volume if not autodiscovered (i.e. a Tape)
#   $storage
#       The storage archive device this pool's volume are in
#   $volume_retetion
#       For how long should the Catalog hold info about each volume
#   $recycle
#       yes, no, defaults to yes. Whether this pool's volumes will be recycled
#   $autoprune
#       yes, no, defaults to yes. Whether autopruning will happen for this pool
#   $label_fmt
#       The format for autolabeled volumes. A good example can be "company-$numvols".
#
# Actions:
#       Will create a pool definition to be included by the director
#
# Requires:
#       bacula::director
#
# Sample Usage:
#       bacula::director::pool { 'company':
#           max_vols   => 10,
#           storage     => 'mystor',
#           volume_retention => '20 days',
#
define bacula::director::pool(
                            $max_vols,
                            $storage,
                            $volume_retention,
                            $catalog_files='yes',
                            $recycle='yes',
                            $autoprune='yes',
                            $max_vol_bytes=undef,
                            $label_fmt=undef) {

    file { "/etc/bacula/conf.d/pool-${name}.conf":
        ensure  => present,
        owner   => root,
        group   => bacula,
        mode    => '0440',
        content => template('bacula/bacula-dir-pool.erb'),
        notify  => Service['bacula-director'],
    }
}

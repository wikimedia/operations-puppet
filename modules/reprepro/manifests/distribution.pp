# == Class: reprepro::distribution
#
#   Configures a reprepro distribution
#
# === Parameters
#
#   - *basedir*: The reprepro base directory.
#   - *settings*: A distributions config map, each key => value will be
#   converted to key: value.
#
# === Example
#
#   class { 'reprepro::distribution':
#     basedir => 'foo',
#     settings => {
#       'distro1' => {
#          'Origin' => 'foo',
#          'Version' => '0.01',
#       }
#     }
#   }
#

class reprepro::distribution (
    $basedir,
    $settings,
) {
    file { "${basedir}/conf/distributions":
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('reprepro/distributions.erb'),
    }
}

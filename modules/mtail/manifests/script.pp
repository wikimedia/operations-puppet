# Definition: mtail::script
#
# Install the given mtail script under the mtail scripts directory. There is no
# need to notify any running mtail instance, changes are picked up by mtail
# in a automatic fashion upon file modification.
#
# Parameters
#   $source
#       The file containing the mtail script to be installed (required).
#   $destdir
#       Destination directory. Defaults to /usr/local/share/mtail.
#
# Usage example:
#   mtail::script { 'xcache':
#       source => 'puppet:///modules/varnish/mtail/xcache.mtail',
#   }
#
define mtail::script($source, $destdir='/usr/local/share/mtail') {
    validate_string($source)
    validate_absolute_path($destdir)

    file { $destdir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { "${destdir}/${title}.mtail":
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$destdir],
    }
}

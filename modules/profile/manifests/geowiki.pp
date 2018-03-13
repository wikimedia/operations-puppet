# == Class profile::geowiki
#
# Installs geowiki and generates geowiki reports.
#
class profile::geowiki {
    # TODO: make this a hiera param.
    $private_data_bare_host = 'stat1006.eqiad.wmnet'

    class { '::geowiki':
        private_data_bare_host => $private_data_bare_host
    }

    # geowiki: bringing data from production slave db to research db
    include ::geowiki::job::data
    # geowiki: generate limn files from research db and push them
    include ::geowiki::job::limn
    # geowiki: monitors the geowiki files of https://stats.wikimedia/geowiki-private
    # Temporary disabled - T173486
    # include ::geowiki::job::monitoring
}

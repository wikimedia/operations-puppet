# == Class statistics::geowiki::data::private
# Makes sure the geowiki's data-private repository is available.
#
class statistics::geowiki::data::private {
    require statistics::geowiki,
        statistics::data::private_bare

    $geowiki_user                   = $statistics::geowiki::geowiki_user
    $geowiki_base_path              = $statistics::geowiki::geowiki_base_path
    $geowiki_private_data_path      = "${geowiki_base_path}/data-private"
    $geowiki_private_data_bare_path = $statistics::data::private_bare::geowiki_private_data_bare_path

    git::clone { 'geowiki-data-private':
        ensure    => 'latest',
        directory => $geowiki_private_data_path,
        origin    => "file://${geowiki_private_data_bare_path}",
        owner     => $geowiki_user,
        group     => 'www-data',
        mode      => '0750',
    }
}


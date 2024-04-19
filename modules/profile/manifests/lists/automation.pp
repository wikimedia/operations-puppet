# SPDX-License-Identifier: Apache-2.0
class profile::lists::automation (
    Stdlib::Unixpath $data_dir = lookup('profile::lists::automation::data_dir', {default_value => '/srv/exports'}),
){

    wmflib::dir::mkdir_p($data_dir, {
        mode  => '0775',
    })

}

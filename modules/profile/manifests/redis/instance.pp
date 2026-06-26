# SPDX-License-Identifier: Apache-2.0
define profile::redis::instance(
    $port=$title,
    $settings={},
    $slaveof=undef,
    $aof=false,
) {
    $slaveof_actual = $slaveof ? {
        /^\S+$/ => "${slaveof} ${port}",
        default => undef
    }

    $base_settings = {
        dbfilename => "${facts['networking']['hostname']}-${title}.rdb",
        slaveof    => $slaveof_actual,
    }

    if $aof {
        $aof_settings = {
            appendfilename => "${facts['networking']['hostname']}-${title}.aof",
        }
    } else {
        $aof_settings = {}
    }

    ::redis::instance { $title:
        settings => merge($base_settings, $aof_settings, $settings)
    }

}

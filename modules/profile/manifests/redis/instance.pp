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

    if $aof {
        $base_settings = {
            appendfilename => "${::hostname}-${title}.aof",
            dbfilename     => "${::hostname}-${title}.rdb",
            slaveof        => $slaveof_actual,
        }
    } else {
        $base_settings = {
            dbfilename => "${::hostname}-${title}.rdb",
            slaveof    => $slaveof_actual,
        }
    }

    redis::instance { $title:
        settings => merge($base_settings, $settings)
    }

}

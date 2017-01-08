# Class for installing an Html5Depurate service
# https://www.mediawiki.org/wiki/Html5Depurate
class role::html5depurate::server {
    system::role { 'role::html5depurate::server':
        description => 'Html5Depurate server',
    }

    $max_memory_mb = ceiling($::memorysize_mb * 0.5)

    class { '::html5depurate':
        listen_host   => '0.0.0.0',
        max_memory_mb => $max_memory_mb,
    }

    include ::html5depurate::monitoring
}

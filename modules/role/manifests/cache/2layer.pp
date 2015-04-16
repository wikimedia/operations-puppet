# Ancestor class for common resources of 2-layer clusters
class role::cache::2layer {
    # Any changes here will affect all descendent Varnish clusters
    # unless they're overridden!
    include role::cache::base
    # This is now only used for director retries math, not for setting the
    # actual backend weights.  The math itself has been left alone, as
    # this will be close enough to approximate previous behavior before
    # $backend_scaled_weights and we're not making things notably worse.
    # It can be fixed later here and/or in the chash code.  See also:
    # https://phabricator.wikimedia.org/P485
    $backend_weight_avg = 100

    if $::realm == 'production' {
        $storage_size_main = $::hostname ? {
            /^cp10(08|4[34])$/      => 117, # Intel X-25M 160G
            /^cp30(0[3-9]|1[0-4])$/ => 460, # Intel M320 600G via H710
            /^cp301[5-8]$/          => 225, # Intel M320 300G via H710
            default                 => 360, # Intel S3700 400G
        }

        # This scales backend weights proportional to node storage size,
        # with the default value of 100 corresponding to the most
        # common/current case of 360G storage size on Intel S3700's.
        $backend_scaled_weights = [
            { backend_match => '^cp10(08|4[34])\.',      weight => 32  },
            { backend_match => '^cp30(0[3-9]|1[0-4])\.', weight => 128 },
            { backend_match => '^cp301[5-8]\.',          weight => 63  },
            { backend_match => '.',                      weight => 100 },
        ]

        # These variables are unused, they just serve as documentation of
        # manual things for now.  This is the equivalent of
        # $backend_scaled_weights above for pybal frontend weighting.
        #
        # The eqiad/upload, esams/upload, and esams/text clusters need
        # differential weighting in pybal due to variance in their nodes'
        # class of CPU power for HTTPS.  This documents the necessary
        # weight ratios, which are created from 'openssl speed aes-128-cbc'
        # for 1K blocksize multiplied by CPU core count then GCD-scaled
        # down within each datacenter to keep weight sums below ipvs sh
        # limits (256 total).
        $pybal_weight_esams_upload_text = [
            '^cp30[34][0-9]'       => 10, # newer esams cp30xx
            '^cp30(0[3-9]|1[0-8])' => 3,  # older esams cp30xx
        ]
        $pybal_weight_eqiad_upload = [
            '^cp107[1-4]'          => 9, # newer eqiad cp10xx
            '^cp10..'              => 4, # older eqiad cp10xx
        ]
    }
    else {
        # for upload on jessie, bigobj is main/6, so 6 is functional minimum here.
        $storage_size_main = 6
        $backend_scaled_weights = [ { backend_match => '.', weight => 100 } ]
    }

    # Ganglia monitoring
    if $::role::cache::configuration::has_ganglia{
        class { 'varnish::monitoring::ganglia':
            varnish_instances => [ '', 'frontend' ],
        }
    }
}

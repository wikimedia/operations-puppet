# To be included by all concrete 2layer cache roles
class role::cache::2layer {
    include role::cache::base

    # Ganglia monitoring
    if $::role::cache::configuration::has_ganglia {
        class { 'varnish::monitoring::ganglia':
            varnish_instances => [ '', 'frontend' ],
        }
    }

    # everything from here down is related to backend storage/weight config

    # This is now only used for director retries math, not for setting the
    # actual backend weights.  The math itself has been left alone, as
    # this will be close enough to approximate previous behavior before
    # $backend_scaled_weights and we're not making things notably worse.
    # It can be fixed later here and/or in the chash code.  See also:
    # https://phabricator.wikimedia.org/P485
    $backend_weight_avg = 100

    $storage_size = $::hostname ? {
        /^cp10(08|4[34])$/      => 117, # Intel X-25M 160G
        /^cp30(0[3-9]|1[0-4])$/ => 460, # Intel M320 600G via H710
        /^cp301[5-8]$/          => 225, # Intel M320 300G via H710
        /^cp[0-9]{4}$/          => 360, # Intel S3700 400G (prod default)
        default                 => 6,   # 6 is the bare min, for e.g. virtuals
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

    # mma: mmap addrseses for fixed persistent storage on x86_64 Linux:
    #  This scheme fits 4x fixed memory mappings of up to 4TB each
    #  into the range 0x500000000000 - 0x5FFFFFFFFFFF, which on
    #  x86_64 Linux is in the middle of the user address space and thus
    #  unlikely to ever be used by normal, auto-addressed allocations,
    #  as those grow in from the edges (typically from the top, but
    #  possibly from the bottom depending).  Regardless of which
    #  direction heap grows from, there's 32TB or more for normal
    #  allocations to chew through before they reach our fixed range.
    $mma = [
        '0x500000000000',
        '0x540000000000',
        '0x580000000000',
        '0x5C0000000000',
    ]

    # Everything else relies on length-two arrays here!
    $storage_parts = $::realm ? {
        production => [ 'sda3', 'sdb3' ],
        labs => [ 'vdb', 'vdb' ],
    }

    $filesystems = unique($storage_parts)
    varnish::setup_filesystem { $filesystems: }
    Varnish::Setup_filesystem <| |> -> Varnish::Instance <| |>

    # This is the "normal" persistent storage varnish args, for consuming all available space
    # (upload uses something more complex than this based on our storage vars above as well!)
    $persistent_storage_args = join([
        "-s main1=persistent,/srv/${storage_parts[0]}/varnish.main1,${storage_size}G,${mma[0]}",
        "-s main2=persistent,/srv/${storage_parts[1]}/varnish.main2,${storage_size}G,${mma[1]}",
    ], ' ')
}

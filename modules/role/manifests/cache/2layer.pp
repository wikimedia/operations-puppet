# To be included by all concrete 2layer cache roles
class role::cache::2layer(
    $storage_parts = undef
) {
    include role::cache::base

    include role::cache::statsd::frontend

    # Ganglia monitoring
    if $::standard::has_ganglia {
        class { 'varnish::monitoring::ganglia':
            varnish_instances => [ '', 'frontend' ],
        }
    }

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

    # everything from here down is related to backend storage/weight config

    $storage_size = $::hostname ? {
        /^cp10(08|4[34])$/      => 117, # Intel X-25M 160G
        /^cp30(19|2[012])$/     => 220, # Seagate ST9250610NS - 250G
        /^cp400[1234]$/         => 220, # Seagate ST9250610NS - 250G
        /^cp30(0[3-9]|1[0-4])$/ => 460, # Intel M320 600G via H710
        /^cp301[5-8]$/          => 225, # Intel M320 300G via H710
        /^cp[0-9]{4}$/          => 360, # Intel S3700 400G (prod default)
        default                 => 6,   # 6 is the bare min, for e.g. virtuals
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

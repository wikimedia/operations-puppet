# == Define: raid::policy
#
# Define to set up cache policies of a RAID controller.
#
# === Limitations
#
# This define currently only works with MegaRAID controllers and while it's
# currently fairly specific to it, it is a more generic abstraction that could
# be later expanded to other controllers (most notably, hpssacli).
#
# It only supports only a few limited hand-picked policies.
#
# It currently assumes that the desired policies on a system need to be be
# uniform across all logical drives, and doesn't support setting them on a
# per-LD basis.
#
# Finally, it doesn't support an "ensure" parameter, that would allow rolling
# back some of those features back, but that can be worked around by setting
# the opposite policy (e.g. set WriteThrough instead of WriteBack absent)
#
# === Parameters
#
# === Examples
#
#  raid::policy { 'writeback': }

define raid::policy($policy=$name) {
    require raid

    if !('megaraid' in $facts['raid']) {
        fail('This module currently works only with MegaRAID controllers')
    }

    if ($policy == 'writeback') {
        $property = 'WB'
        $look_for = 'WriteBack'
    } elsif ($policy == 'writethrough') {
        $property = 'WT'
        $look_for = 'WriteThrough'
    } elsif ($policy == 'direct') {
        $property = 'Direct'
        $look_for = 'Direct'
    } elsif ($policy == 'cached') {
        $property = 'Cached'
        $look_for = 'Cached'
    } elsif ($policy == 'no-cache-badbbu') {
        $property = 'NoCachedBadBBU'
        $look_for = 'No Write Cache if Bad BBU'
    } elsif ($policy == 'readahead') {
        $property = 'RA' # previously known as ADRA
        $look_for = 'ReadAdaptive'
    }

    exec { "megacli SetProp ${property}":
        command => "megacli -LDSetProp ${property} -LALL -aALL",
        onlyif  => "test $(megacli -LDInfo -LALL -aALL | \
                   grep 'Default Cache Policy:' | \
                   grep -v '${look_for}(,|$)' | wc -l) -gt 0"
    }
}

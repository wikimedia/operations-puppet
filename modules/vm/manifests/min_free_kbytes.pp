# SPDX-License-Identifier: Apache-2.0

# set vm.min_free_kbytes to $pct of total RAM, clamped
#  to absolute $min/$max kbytes
define vm::min_free_kbytes($pct, $min, $max) {

    # calculate min_free_spec according to the input params
    $min_free_from_pct = floor($::memorysize_mb * 1024 * $pct / 100)
    if $min_free_from_pct > $max {
        $min_free_spec = $max
    }
    elsif $min_free_from_pct < $min {
        $min_free_spec = $min
    }
    else {
        $min_free_spec = $min_free_from_pct
    }

    # Safety checks: out-of-whack values can break a machine!

    # calculate an absolute max safety boundary at 10%
    # (if someone really has a reason to go beyond that,
    #  they deserve to come look here first before they
    #  break something)
    $max_safety = floor($::memorysize_mb * 1024 / 10)

    # min safety is hardcoded at 8MB
    $min_safety = 8192

    if $min_free_spec < $min_safety {
        $min_free = $min_safety
        warning("vm::min_free_kbytes - calculated value ${min_free_spec} clamped upwards to ${min_safety} for safety reasons!")
    }
    elsif $min_free_spec > $max_safety {
        $min_free = $max_safety
        warning("vm::min_free_kbytes - calculated value ${min_free_spec} clamped downwards to ${max_safety} for safety reasons!")
    }
    else {
        $min_free = $min_free_spec
    }

    sysctl::parameters { 'vm_min_free_kbytes':
        values => { 'vm.min_free_kbytes' => $min_free },
    }
}

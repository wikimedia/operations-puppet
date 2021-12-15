# @summary add helper function to support deep mergeing with arrays
#   The deep_merge function from stdlib only supports deep mergeing Hash's
#   this function wraps that to also support Arrays
function wmflib::deep_merge(
    Hash $hash1,
    Hash $hash2,
) >> Hash {
    if $hash1 == $hash2 {
        return $hash1
    }
    Hash((deep_merge($hash1, $hash2)).map |$key, $value| {
        if $key in $hash1 and $value =~ Array and $hash1[$key] =~ Array {
            [$key, $value + $hash1[$key]]
        } else {
            [$key, $value]
        }
    })
}

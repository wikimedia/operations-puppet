# @summary Convert a number of bytes to a size format that LVM can understand
#
# @return LVM-formatted size
#
# @example Return `200g`
#
#   lvm::bytes_to_size(214748364800)
function lvm::bytes_to_size (
  Numeric $size,
) {
  $units = {
    'k' => 1024,
    'm' => 1048576,
    'g' => 1073741824,
    't' => 1099511627776,
    'p' => 1.12589991e15,
    'e' => 1.1529215e18,
  }
  $remaining_units = $units.filter |$name, $number| {
    # Run all the calculation and return only units that are greater than one
    $size_as_unit = $size / $number
    $size_as_unit >= 1
  }

  # Use the last unit
  $largest_unit = $remaining_units.keys[-1]

  $value = ($size / $units[$largest_unit])

  # # Return the string
  "${value}${largest_unit}"
}

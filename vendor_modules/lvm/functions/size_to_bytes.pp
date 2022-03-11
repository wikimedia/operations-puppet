function lvm::size_to_bytes (
  String $size,
) {
  $units = {
    'K' => 1024,
    'M' => 1048576,
    'G' => 1073741824,
    'T' => 1099511627776,
    'P' => 1.12589991e15,
    'E' => 1.1529215e18,
  }
  # Check if the size is valid and if so, extract the units
  if $size =~ /^([0-9]+(\.[0-9]+)?)([KMGTPEkmgtpe])/ {
    $unit   = String($3, '%u') # Store the units in uppercase
    $number = Float($1)       # Store the number as a float

    # Multiply the number by the units to get bytes
    $number * $units[$unit]
  } else {
    fail("${size} is not a valid LVM size")
  }
}

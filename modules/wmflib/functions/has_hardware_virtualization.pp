# SPDX-License-Identifier: Apache-2.0
# @summary Determines if the host has hardware virtualization support.
# @return [Boolean] true if the host has hardware virtualization support, false otherwise.
function wmflib::has_hardware_virtualization() >> Boolean {
    if $facts['is_virtual'] {
        return false
    }
    # Check for hardware virtualization flags in the CPU details.
    return 'vmx' in $facts['cpu_details']['flags'] or 'svm' in $facts['cpu_details']['flags']
}

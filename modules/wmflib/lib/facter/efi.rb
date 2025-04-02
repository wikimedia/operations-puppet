# SPDX-License-Identifier: Apache-2.0
require "facter"

Facter.add(:efi) do
  confine kernel: "Linux"
  # This directory only exists on a machine booted via EFI
  setcode { File.directory?("/sys/firmware/efi") }
end

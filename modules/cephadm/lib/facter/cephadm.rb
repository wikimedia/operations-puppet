# SPDX-License-Identifier: Apache-2.0
Facter.add(:cephadm) do
  confine do
    File.exists?('/root/.ssh/id_cephadm.pub')
  end

  setcode do
    {
      ssh: {
        key: File.read('/root/.ssh/id_cephadm.pub').chomp
      }
    }
  end
end

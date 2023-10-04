# SPDX-License-Identifier: Apache-2.0
require_relative '../../../puppet_x/wmflib/monkey_patch.rb'

Puppet::Functions.create_function(:'wmflib::monkey_patch') do
  def monkey_patch
    PuppetX::Wmflib::ResolveMonkeypatch.apply_patch
  end
end

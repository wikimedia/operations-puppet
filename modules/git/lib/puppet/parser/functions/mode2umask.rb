# SPDX-License-Identifier: Apache-2.0
module Puppet::Parser::Functions
  newfunction(:mode2umask, type: :rvalue, arity: 1) do |arguments|
    value = arguments[0]
    mask = (value.to_i(8) & 0o0777) ^ 0o0777
    return format('%03o', mask)
  end
end

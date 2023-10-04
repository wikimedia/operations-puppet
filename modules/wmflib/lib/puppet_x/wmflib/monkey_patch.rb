# SPDX-License-Identifier: Apache-2.0
require 'resolv'
# Monkey patch resolv to fix https://github.com/ruby/resolv/issues/24
# https://github.com/ruby/resolv/pull/25
# see T314776 for further details
module PuppetX
  module Wmflib
    module ResolveMonkeypatch
      def self.apply_patch
        const = begin
                  Kernel.const_get('Resolv::IPv6')
                rescue NameError
                  # do nothing
                  nil
                end
        if const
          const.prepend(InstanceMethods)
        end
      end

      module InstanceMethods
        def to_s
          format("%x:%x:%x:%x:%x:%x:%x:%x", *@address.unpack("nnnnnnnn")).sub(/(^|:)0(:0)+(:|$)/, '::')
        end
      end
    end
  end
end

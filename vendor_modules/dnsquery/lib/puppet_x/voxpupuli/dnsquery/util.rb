# frozen_string_literal: true

module PuppetX
  module Voxpupuli
    module Dnsquery
      module Utils
        def self.resolver(config_info = nil)
          if config_info
            Resolv::DNS.new(config_info.transform_keys(&:to_sym))
          else
            Resolv::DNS.new
          end
        end
      end
    end
  end
end

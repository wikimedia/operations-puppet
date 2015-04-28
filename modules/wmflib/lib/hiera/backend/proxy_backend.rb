# Proxy Hiera backend - for complex hiera queries
#
# Author: Giuseppe Lavagetto
# Copyright  (c) 2015 Wikimedia Foundation
#
# This backend allows you to plug multiple simpler backends that use
# Backend.datasources in their lookup method to work toghether as if
# they were part of the same hierarchy.
#

# Add Hiera::Config the ability to get overridden values
# We use this to trick the other backends in doing one and only one
# lookup each
class Hiera::Config
  class << self
    def []=(key,value)
      @config[key] = value
    end
  end
end

class Hiera
  module Backend
    class Proxy_backend
      def initialize
        Hiera.debug "Starting the proxy backend"
        @config = Config[:proxy]
        self.load_plugins
      end

      def load_plugins
        @plugins ||={}
        #Load plugins only once
        @config[:plugins].each do |plugin|
          Hiera.debug "Loading plugin #{plugin}"
          begin
            require "hiera/backend/#{plugin.downcase}_backend"
            @plugins[plugin] ||=
              Backend.const_get("#{plugin.capitalize}_backend").new
          rescue
            Hiera.warn "Failure: plugin #{plugin} failed to load"
          end
        end
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        hierarchy = Config[:hierarchy].clone

        Backend.datasources(scope, order_override) do |source|
          if source.include? '@@'
            plugin, source = source.split('@@')
          else
            plugin = @config[:default_plugin]
          end
          if not @plugins.include? plugin
            Hiera.
              warn "Hierarchy specifies to use plugin '#{plugin}' but can't find it"
            next
          end
          # We look up onto a foreign backend by limiting us to a
          # single element of hierarchy.
          Config[:hierarchy] = [source]
          new_answer = @plugins[plugin].
                       lookup(key, scope, order_override,
                              resolution_type)
          Config[:hierarchy] = hierarchy

          next if new_answer.nil?

          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array
            # The plugins already return an array of answers, so just concatenate it.
            answer ||= []
            answer += new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer,answer)
          else
            answer = new_answer
            break
          end
        end

        answer
      end
    end
  end
end

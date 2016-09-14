require "hiera/httpcache"
class Hiera
  module Backend
    class Httpyaml_backend
      def initialize
        @cache = Httpcache.new
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        Hiera.debug("Looking up #{key}")

        Backend.datasources(scope, order_override) do |source|
          # Small hack: We don't want to search any datasource but the
          # httpyaml/%{::labsproject} hierarchy here; so we plainly exit
          # in any other case.
          next unless source.start_with?('httpyaml/') && source.length > 'httpyaml/'.length

          data = @cache.read(source)

          next if data.nil? || data.empty?
          next unless data.include?(key)

          new_answer = Backend.parse_answer(data[key], scope)
          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of?(Array) || new_answer.kind_of?(String)
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer, answer)
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

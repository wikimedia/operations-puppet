require "hiera/mwcache"
class Hiera
  module Backend
    class Mwyaml_backend
      def initialize(cache=nil)
        @cache = cache || Mwcache.new
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        Hiera.debug("Looking up #{key}")

        Backend.datasources(scope, order_override) do |source|
          # Small hack: - we don't want to search any datasource but the
          # labs/%{::instanceproject} hierarchy here; so we plainly exit
          # in any other case
          if m = /labs\/([^\/]+)$/.match(source)
            source = m[1].capitalize
          else
            next
          end
          data = @cache.read(source, Hash, {}) do |content|
            YAML.load(content)
          end

          next if data.nil? or data.empty?
          next unless data.include?(key)

          new_answer = Backend.parse_answer(data[key], scope)
          case resolution_type
          when :array
            raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
            answer ||= []
            answer << new_answer
          when :hash
            raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
            answer ||= {}
            answer = Backend.merge_answer(new_answer,answer)
          else
            answer = new_answer
            break
          end
        end

        return answer
      end
    end
  end
end

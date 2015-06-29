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
          # labs/%{::labsproject} hierarchy here; so we plainly exit
          # in any other case
          next unless source[0,5] == 'labs/'
          source_arr = source.split('/')
          next if source_arr[1].nil?
          source = source_arr[1].capitalize

          data = @cache.read(source, Hash, {}) do |content|
            YAML.load(content)
          end

          next if data.nil? || data.empty?
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

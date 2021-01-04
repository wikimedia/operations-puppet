module Puppet_X
  module LVM
    # Work with LVM Output
    class Output
      # Parses the results of LVMs commands. This does not handle when columns
      # have no data and therefore these columns should be avoided. It returns
      # the data with the prefix removed i.e. "lv_free" would be come "free"
      # this however doesn't descriminate and will turn something like
      # "foo_bar" into "bar"
      def self.parse(key, columns, data)
        results = {}

        # Remove prefixes
        columns = remove_prefixes(columns)
        key     = remove_prefix(key)

        data.split("\n").each do |line|
          parsed_line = line.gsub(%r{\s+}, ' ').strip.split(' ')
          values      = Hash[columns.zip(parsed_line)]
          current_key = values[key]
          values.delete(key)
          results[current_key] = values
        end

        results
      end

      def self.remove_prefixes(array)
        array.map do |item|
          remove_prefix(item)
        end
      end

      def self.remove_prefix(item)
        item.gsub(%r{^[A-Za-z]+_}, '')
      end
    end
  end
end

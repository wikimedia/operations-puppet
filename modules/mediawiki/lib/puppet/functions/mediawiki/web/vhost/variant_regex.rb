# This function will return a regex to use in apache ProxyPassMatch directives.

Puppet::Functions.create_function(:'mediawiki::web::vhost::variant_regex') do
  dispatch :variant_regex do
    param 'Array[String]', :aliases
    return_type 'String'
  end

  def variant_regex(aliases)
    hierarchy ||= {}
    # first scan all the aliases, organize them hierarchically
    aliases.each  do |al|
      if al.match(/^\w+$/)
        hierarchy[al] ||= []
      elsif match = al.match(/^(\w+)-(\w+)/) # rubocop:disable Lint/AssignmentInCondition
        k, v = match.captures
        hierarchy[k] ||= []
        hierarchy[k] << v
      end
    end
    regexes = []
    hierarchy.each do |prefix, suffixes|
      unless suffixes.empty?
        regexes << "#{prefix}(-(#{suffixes.join('|')}))"
      end
    end
    if regexes.length > 1
      "^/(#{regexes.join('|')})"
    else
      "^/#{regexes[0]}"
    end
  end
end

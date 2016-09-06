#!/usr/bin/ruby
domains = {}
File.read('modules/mediawiki/files/apache/sites/redirects/redirects.dat').each_line do |line|
  if line[0] != '#' and line.strip != '' then
    parts = line.strip.split("\t")
    type = parts[0]
    domain = parts[1]
    if domain.include? "*" then
      next # TODO: Figure out these cases
    end

    target = parts[2]
    if target[0..1] == '//' then
      target = 'https:' + target
    end

    if type == 'override' then
      urlparts = domain.split("/")
      domain = urlparts[0]
      path = "/" + urlparts[1..urlparts.length-1].join("/")
    elsif type == 'rewrite' then
      path = nil
      target = target + "/$1"
    elsif type == 'funnel' then
      path = nil
    end

    if !domains.include? domain then
      domains[domain] = {}
    end
    domains[domain][path] = target
  end
end

require 'yaml'
puts YAML.dump(domains)
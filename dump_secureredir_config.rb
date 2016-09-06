#!/usr/bin/ruby
domains = {}
File.read('modules/mediawiki/files/apache/sites/redirects/redirects.dat').each_line do |line|
  if line[0] == '#' || line.strip == ''
    next
  end
  parts = line.strip.split("\t")
  type = parts[0]
  domain = parts[1]
  if domain.include? "*"
    next # TODO: Figure out these cases
  end

  target = parts[2]
  if target[0..1] == '//'
    target = 'https:' + target
  end

  if type == 'override'
    urlparts = domain.split("/")
    domain = urlparts[0]
    path = "/" + urlparts[1..urlparts.length - 1].join("/")
  elsif type == 'rewrite'
    path = nil
    target += "/$1"
  elsif type == 'funnel'
    path = nil
  end

  if !domains.include? domain
    domains[domain] = {}
  end
  domains[domain][path] = target
end

require 'yaml'
puts YAML.dump(domains)

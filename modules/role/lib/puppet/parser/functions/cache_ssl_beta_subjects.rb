# == Function: cache_ssl_beta_subjects()
#
# Returns a list of domains to be set as the text cache's SSL certificate subjects
module Puppet::Parser::Functions
  newfunction(:cache_ssl_beta_subjects, :type => :rvalue, :arity => 0) do |args|
    out = []
    wiki_sites = [
      ['commons', 'wikimedia'],
      ['deployment', 'wikimedia'],
      ['en', 'wikibooks'],
      ['en', 'wikinews'],
      ['en', 'wikiquote'],
      ['en', 'wikisource'],
      ['en', 'wikiversity'],
      ['en', 'wikivoyage'],
      ['en', 'wiktionary'],
      ['login', 'wikimedia'],
      ['meta', 'wikimedia'],
      ['test', 'wikimedia'],
      ['wikidata'],
      ['zero', 'wikimedia'],
      ['aa', 'wikipedia'],
      ['ar', 'wikipedia'],
      ['ca', 'wikipedia'],
      ['de', 'wikipedia'],
      ['en-rtl', 'wikipedia'],
      ['en', 'wikipedia'],
      ['eo', 'wikipedia'],
      ['es', 'wikipedia'],
      ['fa', 'wikipedia'],
      ['he', 'wikipedia'],
      ['hi', 'wikipedia'],
      ['ja', 'wikipedia'],
      ['ko', 'wikipedia'],
      ['nl', 'wikipedia'],
      ['ru', 'wikipedia'],
      ['simple', 'wikipedia'],
      ['sq', 'wikipedia'],
      ['uk', 'wikipedia'],
      ['zh', 'wikipedia'],
    ]

    wiki_sites.each { |site|
      if site.length == 2
        subsite, project = site
        out.push( "#{subsite}.#{project}.beta.wmflabs.org" )
        out.push( "#{subsite}.m.#{project}.beta.wmflabs.org" )
        if project === 'wikipedia'
          out.push( "#{subsite}.zero.wikipedia.beta.wmflabs.org" )
        end
      elsif site.length == 1
        project, = site
        out.push( "#{project}.beta.wmflabs.org" )
        out.push( "m.#{project}.beta.wmflabs.org" )
      end
    }

    out.push( 'beta.wmflabs.org' )
    out.push( 'www.wikimedia.beta.wmflabs.org' )
    out.push( 'www.wikipedia.beta.wmflabs.org' )
    out.push( 'commons.wikipedia.beta.wmflabs.org' )
    out
  end
end

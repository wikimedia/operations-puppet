source 'https://rubygems.org'

gem 'puppet'
gem 'facter'

gem 'rspec-puppet',
    # We need rspec-puppet v2.0.0+ to fix a rspec matcher protocol error in
    # v1.0.1. Unfortunately it has not been released on rubygems so we fetch
    # directly from github using the sha1 ref.
    #
    # Refs:
    # https://github.com/rodjek/rspec-puppet/pull/142
    # https://github.com/rodjek/rspec-puppet/commit/b6b298f
    :github => 'rodjek/rspec-puppet',
    # v2.0.0
    :ref => '43fea603a5f308731e9b51337fb9adc66fa72d18'

require_relative '../../../../rake_modules/spec_helper'

describe 'Wmflib::Host::Wildcard' do
  describe 'valid handling' do
    ['en.wikipedia.org',
     '*.wikipedia.org'].each do |value|
      describe value.inspect do
        it { is_expected.to allow_value(value) }
      end
    end
  end
  describe 'invalid handling' do
    ['ww*.wikipedia.org',
     '*e.wikipedia.org'].each do |value|
      describe value.inspect do
        it { is_expected.not_to allow_value(value) }
      end
    end
  end
end

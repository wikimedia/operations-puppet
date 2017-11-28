require 'spec_helper'

describe 'puppetmaster::rsync' do
    let(:params) { {
        :server => 'puppetmaster_host',
    } }
    let(:facts) { {
        :realm => 'production',
    } }
    it { should compile }
end

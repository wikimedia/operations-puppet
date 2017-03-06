require 'spec_helper'

describe 'backup::hourlyschedule', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :pool => 'unimportant',
    }
    }
    let(:pre_condition) do
       [
            'define bacula::director::jobdefaults($when, $pool) {}',
            'define bacula::director::schedule($runs) {}',
       ]
    end
    it 'should create bacula::director::jobdefaults' do
        should contain_bacula__director__jobdefaults("Hourly-#{title}-unimportant").with({
            'when'    => "Hourly-#{title}",
            'pool'    => 'unimportant',
        })
    end
    it 'should create bacula::director::schedule' do
        should contain_bacula__director__schedule("Hourly-#{title}")
    end
end

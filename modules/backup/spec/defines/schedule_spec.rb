require 'spec_helper'

describe 'backup::schedule', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :pool => 'unimportant'
    }
    }
    let(:pre_condition) do
       [
            'define bacula::director::jobdefaults($when, $pool) {}',
            'define bacula::director::schedule($runs) {}',
       ]
    end
    it 'should create bacula::director::jobdefaults' do
        should contain_bacula__director__jobdefaults("Monthly-1st-#{title}-unimportant").with({
            'when'    => "Monthly-1st-#{title}",
            'pool'    => 'unimportant',
        },)
    end
    it 'should create bacula::director::schedule' do
        should contain_bacula__director__schedule("Monthly-1st-#{title}")
    end
end

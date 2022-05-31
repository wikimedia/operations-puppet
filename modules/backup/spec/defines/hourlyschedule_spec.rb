# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'backup::hourlyschedule', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :day => 'oneday',
    }
    }
    let(:pre_condition) do
        [
            'define bacula::director::schedule($runs) {}',
        ]
    end
    it 'should create bacula::director::schedule' do
        should contain_bacula__director__schedule('Hourly-oneday')
    end
end

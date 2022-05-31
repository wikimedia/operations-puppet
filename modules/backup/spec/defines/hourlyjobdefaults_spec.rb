# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'backup::hourlyjobdefaults', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :day  => 'oneday',
        :pool => 'unimportant',
    }
    }
    let(:pre_condition) do
        [
            'define bacula::director::jobdefaults($when, $pool) {}',
        ]
    end
    it 'should create bacula::director::jobdefaults' do
        should contain_bacula__director__jobdefaults('Hourly-oneday-unimportant').with({
            'when' => 'Hourly-oneday',
            'pool' => 'unimportant',
        })
    end
end

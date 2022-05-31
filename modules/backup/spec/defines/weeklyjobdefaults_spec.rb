# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'backup::weeklyjobdefaults', :type => :define do
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
        should contain_bacula__director__jobdefaults('Weekly-oneday-unimportant').with({
            'when' => 'Weekly-oneday',
            'pool' => 'unimportant',
        })
    end
end

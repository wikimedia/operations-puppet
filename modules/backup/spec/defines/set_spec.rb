require 'spec_helper'

describe 'backup::set', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :jobdefaults => 'unimportant'
    }
    }
    let(:pre_condition) do
        [
            'File <| |>',
            'define bacula::client::job($fileset, $jobdefaults) {}',
        ]
    end
end

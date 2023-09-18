# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'dbutils::statement' do
    let(:title) { 'some_stmt' }

    context "defaults" do
        let(:params) {{
            'statement' => "x",
            'unless' => "y",
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('db-statement-some_stmt')
            .with_command("/usr/bin/mysql --user=root --batch --silent -e \"x;\"")
            .with_unless("/usr/bin/mysql --user=root --batch --silent -e \"y;\" | grep -q \"x\"")
            .with_user("root")
            .with_timeout("30")
        }
    end

    context "grep match" do
        let(:params) {{
            'statement' => "x",
            'unless' => "y",
            'unless_grep_match' => "z",
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('db-statement-some_stmt')
            .with_command("/usr/bin/mysql --user=root --batch --silent -e \"x;\"")
            .with_unless("/usr/bin/mysql --user=root --batch --silent -e \"y;\" | grep -q \"z\"")
            .with_user("root")
            .with_timeout("30")
        }
    end
end

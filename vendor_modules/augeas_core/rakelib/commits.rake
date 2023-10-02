desc "verify that commit summaries are properly formatted"
task(:commits) do
  # This rake task looks at the summary from every commit from this branch not
  # in the branch targeted for a PR.
  commit_range = 'HEAD^..HEAD'
  puts "Checking commits #{commit_range}"
  %x{git log --no-merges --pretty=%s #{commit_range}}.each_line do |commit_summary|
    # This regex tests for the currently supported commit summary tokens.
    # The exception tries to explain it in more full.
    if /^Release prep|\((maint|packaging|doc|docs|modules|pa-\d+)\)|revert/i.match(commit_summary).nil?
      raise "\n\n\n\tPlease make sure that your commit summary (i.e. the first line of the commit message) starts with one of the following:\n"  \
        "\t\t(PA-<digits>)\n" \
        "\t\t(MODULES-<digits>)\n" \
        "\t\t(docs)\n" \
        "\t\t(docs)(DOCUMENT-<digits>)\n" \
        "\t\t(packaging)\n"
        "\t\t(maint)\n" \
        "\t\tRelease prep v<tag>\n" \
        "\n\tThis test for the commit summary is case-insensitive.\n\n\n"
    else
      puts "#{commit_summary}"
    end
    puts "...passed"
  end
end

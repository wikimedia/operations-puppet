# -*- coding: UTF-8 -*-
#
# == Function: vcl_app_directors( hash $app_directors )
#
# Creates a block of VCL code intended to chose an application-layer backend
# director at vcl_recv() time.
#
# === Examples
#
# ....
#
module Puppet::Parser::Functions
  newfunction(:vcl_app_directors, :type => :rvalue, :arity => 1) do |args|
    Puppet::Parser::Functions.function(:hiera)
    varnish_version4 = function_hiera(['varnish_version4', false])
    app_directors = args.first

    stmts = []
    app_directors.keys.sort.each do |dirname|
        dir = app_directors[dirname]
        if dir.key?('req_host')
            hostcmp = [*dir['req_host']].map { |h| %(req.http.Host == "#{h}") }.join(' || ')
        else
            hostcmp = %(req.http.Host ~ "#{dir['req_host_re']}")
        end
        if dir.key?('maintenance')
            action = error_synth(503, dir['maintenance'])
        elsif varnish_version4
            if dir['type'] == 'hash'
                action = "set req.backend_hint = #{dirname}.backend(req.http.X-Client-IP);"
            else
                action = "set req.backend_hint = #{dirname}.backend();"
            end
        else
            action = "set req.backend = #{dirname};\n"
        end
        stmts.push("if (#{hostcmp}) {\n        #{action}")
    end
    if varnish_version4
        stmts.push(%(e {\n        return (synth(404, "Domain not served here"));\n    }))
    else
        stmts.push(%(e {\n        error 404 "Domain not served here";\n    }))
    end
    output = if_stmts.join("\n    } els")
    return output
  end
end

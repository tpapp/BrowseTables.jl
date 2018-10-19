module BrowseTables

export write_html_table, open_html_table, TableOptions

using ArgCheck: @argcheck
import DefaultApplication
using DocStringExtensions: SIGNATURES
import Tables

function writetags(f, io::IO, tag::AbstractString; bropen = true, brclose = bropen)
    write(io, "<", tag, ">")
    bropen || println(io)
    f(io)
    write(io, "</", tag, ">")
    brclose || println(io)
    nothing
end

function writeescaped(io, str::AbstractString)
    for char in str
        if char == '&'
            write(io, "&amp")
        elseif char == '<'
            write(io, "&lt")
        elseif char == '>'
            write(io, "&gt")
        else
            write(io, char)
        end
    end
    nothing
end

writecell(io, x, kind = "td") = writetags(io -> writeescaped(io, string(x)), io, kind)

function writerow(io, nt::NamedTuple)
    writetags(io, "tr") do io
        for x in values(nt)
            writecell(io, x)
        end
    end
end

writecaption(io, ::Nothing) = nothing

writecaption(io, str::AbstractString) = writetags(io -> writeescaped(io, str), io, "caption")

writeschema(io, ::Nothing) = nothing

function writeschema(io, sch::Tables.Schema)
    writetags(io, "thead") do io
        writetags(io, "tr") do io
            foreach(x -> writecell(io, x, "th"), sch.names)
        end
    end
end

function writebody(io, itr)
    writetags(io, "tbody") do
        foreach(row -> writerow(io, row), itr)
    end
end

const HTMLHEADSTART = """
<!DOCTYPE html><html lang="en"><head>
  <meta content="text/html; charset=utf-8" http-equiv="Content-Type">
  <meta content="width=device-width, initial-scale=1, shrink-to-fit=no" name="viewport">
"""

const DEFAULTCSSPATH = abspath(@__DIR__, "..", "assets", "BrowseTables.css")

Base.@kwdef struct TableOptions
    css_path::AbstractString = DEFAULTCSSPATH
    css_inline::Bool = true
end

function writestyle(io::IO, path::AbstractString, inline::Bool)
    if inline
        writetags(io -> write(io, read(path, String)), io, "style")
    else
        println(io, raw"<link href=\"", path, raw"\" rel=\"stylesheet\" type=\"text/css\">")
    end
    nothing
end

function write_html_table(filename::AbstractString, table;
                        title = "Table", caption = nothing, options = TableOptions())
    @argcheck Tables.istable(table) "The table should support the interface of Tables.jl."
    open(filename, "w") do io
        write(io, HTMLHEADSTART)
        writetags(io -> writeescaped(io, title), io, "title")
        writestyle(io, options.css_path, options.css_inline)
        println(io, "</head>")    # close manually, opened in HTMLHEADSTART
        writetags(io, "body") do io
            writetags(io, "table") do io
                writecaption(io, caption)
                rows = Tables.rows(table)
                writeschema(io, Tables.schema(rows))
                foreach(row -> writerow(io, row), rows)
            end
        end
        println(io, "</html>")
    end
    nothing
end

function open_html_table(table; filename = tempname() * ".html", kwargs...)
    write_html_table(filename, table; kwargs...)
    DefaultApplication.open(filename)
end

end # module

module BrowseTables

export write_html_table, open_html_table, TableOptions

using ArgCheck: @argcheck
import DefaultApplication
using DocStringExtensions: SIGNATURES
import Tables


# options and customizations

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


# low-level HTML construction

function writeescaped(io, str::AbstractString)
    for char in str
        if char == '&'
            write(io, "&amp;")
        elseif char == '<'
            write(io, "&lt;")
        elseif char == '>'
            write(io, "&gt;")
        elseif char == '"'
            write(io, "&quot;")
        else
            write(io, char)
        end
    end
    nothing
end

escapestring(str::AbstractString) = (io = IOBuffer(); writeescaped(io, str); String(take!(io)))

function writetags(f, io::IO, tag::AbstractString; bropen = false, brclose = bropen,
                   attributes = NamedTuple())
    write(io, "<", tag)
    for (k, v) in pairs(attributes)
        write(io, " ", string(k), "=\"")
        writeescaped(io, v)
        write(io, "\"")
    end
    write(io, ">")
    bropen && println(io)
    f(io)
    write(io, "</", tag, ">")
    brclose && println(io)
    nothing
end

writecell(io, content::AbstractString; kind = "td", attributes = NamedTuple()) =
    writetags(io -> writeescaped(io, content), io, kind; attributes = attributes)


# cell formatting

"""
$(SIGNATURES)

HTML representation of a cell, with attributes. Content should be escaped properly, as it is
written to HTML directly.
"""
cellwithattributes(::TableOptions, x) = escapestring(string(x)), NamedTuple()

cellwithattributes(::TableOptions, x::Real) =
    escapestring(string(x)), isfinite(x) ? NamedTuple() : (class = "nonfinite", )

cellwithattributes(::TableOptions, str::AbstractString) =
    escapestring(str), (class = "alignleft", )

cellwithattributes(::TableOptions, x::Union{Missing,Nothing}) =
    escapestring(repr(x)), (class = "likemissing", )

struct RowId
    id::Int
end

cellwithattributes(::TableOptions, rowid::RowId) =
    escapestring(string(rowid.id)), (class = "rowid", )


# table structure

function writerow(io, options::TableOptions, nt::NamedTuple)
    writetags(io, "tr"; brclose = true) do io
        for x in values(nt)
            htmlcontent, attributes = cellwithattributes(options, x)
            writecell(io, htmlcontent; attributes = attributes)
        end
    end
end

writecaption(io, ::Nothing) = nothing

writecaption(io, str::AbstractString) = writetags(io -> writeescaped(io, str), io, "caption")

writeschema(io, ::Nothing) = nothing

function writeschema(io, sch::Tables.Schema)
    writetags(io, "thead"; brclose = true) do io
        writetags(io, "tr") do io
            writecell(io, "#"; kind = "th") # row id
            foreach(x -> writecell(io, escapestring(string(x)); kind = "th"), sch.names)
        end
    end
end

function writestyle(io::IO, path::AbstractString, inline::Bool)
    if inline
        writetags(io -> write(io, read(path, String)), io, "style")
    else
        println(io, raw"<link href=\"", path, raw"\" rel=\"stylesheet\" type=\"text/css\">")
    end
    nothing
end


# high-level API

function write_html_table(filename::AbstractString, table;
                          title = "Table", caption = nothing,
                          options::TableOptions = TableOptions())
    @argcheck Tables.istable(table) "The table should support the interface of Tables.jl."
    open(filename, "w") do io
        write(io, HTMLHEADSTART)
        writetags(io -> writeescaped(io, title), io, "title")
        writestyle(io, options.css_path, options.css_inline)
        println(io, "</head>")    # close manually, opened in HTMLHEADSTART
        writetags(io, "body"; bropen = true) do io
            println(io, "<div class='divstyle'>"); ## scroll properties attached 
            writetags(io, "table"; bropen = true) do io
                writecaption(io, caption)
                rows = Tables.rows(table)
                writeschema(io, Tables.schema(rows))
                writetags(io, "tbody"; bropen = true) do io
                    for (id, row) in enumerate(rows)
                        writerow(io, options, merge((rowid = RowId(id),), row))
                    end
                end
        println(io, "</div>"); ## endscroll
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

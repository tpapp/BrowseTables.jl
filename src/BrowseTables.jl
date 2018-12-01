module BrowseTables

export write_html_table, open_html_table, TableOptions

using ArgCheck: @argcheck
import DefaultApplication
using DocStringExtensions: SIGNATURES
import Tables

####
#### options and customizations
####

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

####
#### low-level HTML construction
####

function write_escaped(io, str::AbstractString)
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

escape_string(str::AbstractString) = (io = IOBuffer(); write_escaped(io, str); String(take!(io)))

"""
$(SIGNATURES)

Write tags `<tag>` and `</tag>` to `io` before and after a call to `f(io)`.

`attributes` are emitted in the opening tag. `bropen` and `brclose` determine if a
"""
function write_tags(f, io::IO, tag::AbstractString; bropen = false, brclose = bropen,
                    attributes = NamedTuple())
    write(io, "<", tag)
    for (k, v) in pairs(attributes)
        write(io, " ", string(k), "=\"")
        write_escaped(io, v)
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
    write_tags(io -> write_escaped(io, content), io, kind; attributes = attributes)

####
#### cell formatting
####

"""
$(SIGNATURES)

HTML representation of a cell, with attributes. Content should be escaped properly, as it is
written to HTML directly.
"""
cellwithattributes(::TableOptions, x) = escape_string(string(x)), NamedTuple()

cellwithattributes(::TableOptions, x::Real) =
    escape_string(string(x)), isfinite(x) ? NamedTuple() : (class = "nonfinite", )

cellwithattributes(::TableOptions, str::AbstractString) =
    escape_string(str), (class = "alignleft", )

cellwithattributes(::TableOptions, x::Union{Missing,Nothing}) =
    escape_string(repr(x)), (class = "likemissing", )

struct RowId
    id::Int
end

cellwithattributes(::TableOptions, rowid::RowId) =
    escape_string(string(rowid.id)), (class = "rowid", )

####
#### table structure
####

function writerow(io, options::TableOptions, nt::NamedTuple)
    write_tags(io, "tr"; brclose = true) do io
        for x in values(nt)
            htmlcontent, attributes = cellwithattributes(options, x)
            writecell(io, htmlcontent; attributes = attributes)
        end
    end
end

writecaption(io, ::Nothing) = nothing

writecaption(io, str::AbstractString) =
    write_tags(io -> write_escaped(io, str), io, "caption")

writeschema(io, ::Nothing) = nothing

function writeschema(io, sch::Tables.Schema)
    write_tags(io, "thead"; brclose = true) do io
        write_tags(io, "tr") do io
            writecell(io, "#"; kind = "th") # row id
            foreach(x -> writecell(io, escape_string(string(x)); kind = "th"), sch.names)
        end
    end
end

function writestyle(io::IO, path::AbstractString, inline::Bool)
    if inline
        write_tags(io -> write(io, read(path, String)), io, "style")
    else
        println(io, raw"<link href=\"", path, raw"\" rel=\"stylesheet\" type=\"text/css\">")
    end
    nothing
end

####
#### high-level API
####

"""
$(SIGNATURES)

Write a HTML representation of `table` to `filename`.

`title` and `caption` determine respective parts of the table. They will be escaped.

`options` can be used to specify table options, such as CSS.
"""
function write_html_table(filename::AbstractString, table;
                          title = "Table", caption = nothing,
                          options::TableOptions = TableOptions())
    @argcheck Tables.istable(table) "The table should support the interface of Tables.jl."
    open(filename, "w") do io
        write(io, HTMLHEADSTART)
        write_tags(io -> write_escaped(io, title), io, "title")
        writestyle(io, options.css_path, options.css_inline)
        println(io, "</head>")    # close manually, opened in HTMLHEADSTART
        write_tags(io, "body"; bropen = true) do io
            write_tags(io, "table"; bropen = true) do io
                writecaption(io, caption)
                rows = Tables.rows(table)
                writeschema(io, Tables.schema(rows))
                write_tags(io, "tbody"; bropen = true) do io
                    for (id, row) in enumerate(rows)
                        writerow(io, options, merge((rowid = RowId(id),), row))
                    end
                end
            end
        end
        println(io, "</html>")
    end
    nothing
end

"""
$(SIGNATURES)

Write `table` to `filename` (temporary file is generated by default), then open it using the
default application (hopefully a browser). Keyword arguments are passed on to
[`write_html_table`](@ref).
"""
function open_html_table(table; filename = tempname() * ".html", kwargs...)
    write_html_table(filename, table; kwargs...)
    DefaultApplication.open(filename)
end

end # module

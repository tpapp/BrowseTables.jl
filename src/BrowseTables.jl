module BrowseTables

export write_html_table, open_html_table, TableOptions

using ArgCheck: @argcheck
import DefaultApplication
using DocStringExtensions: SIGNATURES, TYPEDEF
using Parameters: @unpack
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

`attributes` are emitted in the opening tag. `bropen` and `brclose` determine if a newlines
are emitted after the opening and closing tags, respectively.
"""
function write_tags(f, io::IO, tag::AbstractString; bropen::Bool = false,
                    brclose::Bool = bropen, attributes::NamedTuple = NamedTuple())
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

####
#### HTML writing API
####

"""
$(SIGNATURES)

Write the second argument to `io` using its HTML representation. This is used for formatting
string-like objectsinside cells, captions, etc, extend accordingly for custom types.
Defaults to whatever is emitted by `string`.

Extend `make_cell` for higher-level formatting using CSS.
"""
write_html(io::IO, object) = write_html(io, string(object))

write_html(io::IO, content::AbstractString) = write_escaped(io, content)

"""
$(TYPEDEF)

Wrapper for emitting contents which are already formatted as HTML.
"""
struct RawHTML{S <: String}
    html::S
end

write_html(io::IO, raw_html::RawHTML) = write(io, raw_html.html)

"""
$(SIGNATURES)

Content (written using `write_html`) and HTML attributes. HTML tag is specified by caller of
`write_html`.
"""
struct Cell{C, A <: NamedTuple}
    content::C
    attributes::A
end

Cell(content; kwargs...) = Cell(content, NamedTuple{keys(kwargs)}(values(kwargs)))

function write_html(io::IO, kind::Symbol, cell::Cell)
    @unpack content, attributes = cell
    write_tags(io -> write_html(io, content), io, string(kind); attributes = attributes)
end

"""
$(SIGNATURES)

Convert argument to `Cell`, which will be written using `write_html`.
"""
make_cell(::TableOptions, x) = Cell(x, NamedTuple())

make_cell(::TableOptions, x::Real) =
    Cell(x, isfinite(x) ? NamedTuple() : (class = "nonfinite", ))

make_cell(::TableOptions, str::AbstractString) = Cell(str; class = "alignleft")

make_cell(::TableOptions, x::Union{Missing,Nothing}) = Cell(repr(x); class = "likemissing")

####
#### table structure
####

function write_row(io, options::TableOptions, rowid, row)
    write_tags(io, "tr"; brclose = true) do io
        write_html(io, :td, Cell(string(rowid); class = "rowid"))
        for name in propertynames(row)
            write_html(io, :td, make_cell(options, getproperty(row, name)))
        end
    end
end

write_caption(io, ::Nothing) = nothing

write_caption(io, str) = write_tags(io -> write_html(io, str), io, "caption")

"""
$(SIGNATURES)

Write the schema returned by `Tables.schema` (for rows) to `io`, wrapped by `tag`.
"""
write_schema(io, tag, ::Nothing) = nothing

function write_schema(io, tag, sch::Tables.Schema)
    write_tags(io, tag; brclose = true) do io
        write_tags(io, "tr") do io
            write_html(io, :th, Cell("#"; class = "rowid")) # row ID
            for name in sch.names
                write_html(io, :th, Cell(string(name)))
            end
        end
    end
end

"""
$(SIGNATURES)

Write the stylesheet `inline` or via a `<link>`.
"""
function write_style(io::IO, path::AbstractString, inline::Bool)
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
        write(io, HTMLHEADSTART) # contains an opening <head>
        write_tags(io -> write_escaped(io, title), io, "title")
        write_style(io, options.css_path, options.css_inline)
        println(io, "</head>")  # close manually, opened in HTMLHEADSTART
        write_tags(io, "body"; bropen = true) do io
            write_tags(io, "table"; bropen = true) do io
                write_caption(io, caption)
                rows = Tables.rows(table)
                sch = Tables.schema(rows)
                write_schema(io, "thead", sch)
                write_tags(io, "tbody"; bropen = true) do io
                    for (id, row) in enumerate(rows)
                        write_row(io, options, id,  row)
                    end
                end
                write_schema(io, "tfoot", sch)
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

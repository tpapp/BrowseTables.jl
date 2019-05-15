using BrowseTables, Tables, Test
using BrowseTables: escape_string, write_tags, make_cell, write_html

@testset "HTML escapes" begin
    @test escape_string("&<>\"test") == "&amp;&lt;&gt;&quot;test"
end

@testset "tag writing" begin
    io = IOBuffer()
    write_tags(io, "foo"; attributes = (bar = "baz", )) do io
        print(io, "test")
    end
    @test String(take!(io)) == "<foo bar=\"baz\">test</foo>"
end

"For testing `write_html` and representations."
repr_html(args...) = (io = IOBuffer(); write_html(io, args...); String(take!(io)))

const opt = TableOptions()

"For testing cell representations. Uses `<td>` for tags."
repr_cell(x, o = opt) = repr_html(:td, make_cell(o, x))

@testset "cell formatting" begin
    @test repr_cell(1) == "<td>1</td>"
    if VERSION < v"1.2-"
        @test repr_cell(π) == "<td>π = 3.1415926535897...</td>"
    else
        @test repr_cell(π) == "<td>π</td>"
    end
    @test repr_cell(missing) == "<td class=\"likemissing\">missing</td>"
    @test repr_cell(nothing) == "<td class=\"likemissing\">nothing</td>"
    @test repr_cell("string<>") == "<td class=\"alignleft\">string&lt;&gt;</td>"
end

@testset "rudimentary check for whole file" begin
    filename = tempname() * ".html"
    @info "generating HTML for table" filename
    tb = (a = 1:2, b = [missing, 3])
    @test Tables.schema(tb) ≢ nothing # if this fails, interface changed, rewrite test
    write_html_table(filename, tb)
    html = read(filename, String)
    schema_html = "<tr><th class=\"rowid\">#</th><th>a</th><th>b</th></tr>"
    @test occursin("<thead>$(schema_html)</thead>", html)
    @test occursin("<tfoot>$(schema_html)</tfoot>", html)
    @test occursin("<tbody>\n<tr><td class=\"rowid\">1</td><td>1</td>" *
                   "<td class=\"likemissing\">missing</td></tr>\n<tr>" *
                   "<td class=\"rowid\">2</td><td>2</td><td>3</td></tr>\n</tbody>", html)
end

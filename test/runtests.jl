using BrowseTables, Tables, Test
using BrowseTables: escape_string, write_tags

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

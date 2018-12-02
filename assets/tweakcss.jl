# generate and open an example table for tweaking CSS

using BrowseTables

table = collect(NamedTuple{(:a,:b,:c), Tuple{Union{Int,Missing},Float64,Union{String,Nothing}}},
                iszero(i % 10) ? (a = missing, b = NaN, c = nothing) :
                (a = i, b = Float64(i), c = ('a'+(i%26))^((i%7+1))) for i in 1:100)

open_html_table(table; options = TableOptions(; css_inline = false))

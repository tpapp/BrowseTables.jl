# generate and open an example table for tweaking CSS

using BrowseTables, Tables

table = collect((a = i, b = Float64(i), c = 'a'-1+i) for i in 1:30)

open_html_table(table; options = TableOptions(; css_inline = false))

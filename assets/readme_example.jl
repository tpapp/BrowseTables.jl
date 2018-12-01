#####
##### generate the example for the README
#####
##### NOTE run with its own current directory, use `make`

using BrowseTables, Tables
# make example table, but any table that supports Tables.jl will work
table = Tables.columntable(collect(i == 5 ? (a = missing, b = "string", c = nothing) :
                                   (a = i, b = Float64(i), c = 'a'-1+i) for i in 1:10))
file = "readme_example.html"
write_html_table(file, table)

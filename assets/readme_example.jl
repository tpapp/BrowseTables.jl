#####
##### generate the example for the README
#####
##### NOTE run with its own current directory, use `make`

using BrowseTables
# make example table, but any table that supports Tables.jl will work
table = collect((a = i, b = Float64(i), c = 'a'-1+i) for i in 1:10)
file = "readme_example.html"
write_html_table(file, table)

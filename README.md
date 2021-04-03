# BrowseTables.jl

![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
[![build](https://github.com/tpapp/BrowseTables.jl/workflows/CI/badge.svg)](https://github.com/tpapp/BrowseTables.jl/actions?query=workflow%3ACI)
[![codecov.io](http://codecov.io/github/tpapp/BrowseTables.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/BrowseTables.jl?branch=master)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://tpapp.github.io/BrowseTables.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://tpapp.github.io/BrowseTables.jl/dev)

Julia package for browsing tables that that implement the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface, as HTML.

## Installation

The package is registered, install with

```julia
pkg> add BrowseTables
```

## Usage

```julia
using BrowseTables, Tables
# make example table, but any table that supports Tables.jl will work
table = Tables.columntable(collect(i == 5 ? (a = missing, b = "string", c = nothing) :
                                   (a = i, b = Float64(i), c = 'a'-1+i) for i in 1:10))
open_html_table(table) # open in browser
HTMLTable(table) # show HTML table using Julia's display system
```

The package exports four symbols:

1. `write_html_table` writes a table to a HTML file,
2. `open_html_table` writes the table and opens it in a browser using [DefaultApplication.jl](https://github.com/tpapp/DefaultApplication.jl),
3. `TableOptions` can be used to customize table appearance and HTML options for the above two functions.
4. `HTMLTable` displays an HTML table using Julia's display system.  It needs a display supporting HTML output (e.g., [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)).

Please read the docstrings for further information. That said, the primary design principle of this package is that it should “just work”, without further tweaking.

## How it looks

The above table renders as

<img src="./assets/readme_example.svg" width="20%">

# BrowseTables

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.org/tpapp/BrowseTables.jl.svg?branch=master)](https://travis-ci.org/tpapp/BrowseTables.jl)
[![codecov.io](http://codecov.io/github/tpapp/BrowseTables.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/BrowseTables.jl?branch=master)

Julia package for browsing tables that that implement the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface, as HTML.

## Installation

Not yet registered, install with

```julia
pkg> add https://github.com/tpapp/BrowseTables.jl.git
```

## Usage

```julia
using BrowseTables
# make example table, but any table that supports Tables.jl will work
table = collect((a = i, b = Float64(i), c = 'a'-1+i) for i in 1:10)
open_html_table(table) # open in browser
```

## How it looks

The above table renders as

![example rendered as svg](./assets/readme_example.svg)<img src="./assets/readme_example.svg" width="50%">

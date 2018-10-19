using Documenter, BrowseTables

makedocs(
    modules = [BrowseTables],
    format = :html,
    sitename = "BrowseTables.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/tpapp/BrowseTables.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)

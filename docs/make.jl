using DiffFusionServer
using Documenter

DocMeta.setdocmeta!(DiffFusionServer, :DocTestSetup, :(using DiffFusionServer); recursive=true)

makedocs(;
    modules=[DiffFusionServer],
    authors="Sebastian Schlenkrich <sebastian.schlenkrich@frame-consult.de> and contributors",
    repo="https://github.com/frame-consulting/DiffFusionServer.jl/blob/{commit}{path}#{line}",
    sitename="DiffFusionServer.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://frame-consulting.github.io/DiffFusionServer.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/frame-consulting/DiffFusionServer.jl",
    devbranch="main",
)

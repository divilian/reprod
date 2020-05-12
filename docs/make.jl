
using Documenter

include("../src/odCommon.jl")
include("../src/bvm/bvm.jl")

push!(LOAD_PATH, "../src")
push!(LOAD_PATH, "../src/bvm")

makedocs(
    sitename = "reprod (Reproducible Opinion Dynamics)",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [odCommon,bvm],
    pages = [
        "reprod" => "index.md",
        "odCommon" => "odCommon.md",
        "Binary Voter Model" => "bvm.md"
    ]
)

using DiffFusionServer
using Test

@testset "Test server methods." begin

    include("errors.jl")
    include("router.jl")
    include("example.jl")
    include("example_async.jl")

end

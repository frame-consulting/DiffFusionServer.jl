using DiffFusionServer
using Test

@testset verbose=true "DiffFusionServer.jl" begin

    @info "Testing DiffFusionServer."

    include("server/server.jl")
    include("client/client.jl")

end

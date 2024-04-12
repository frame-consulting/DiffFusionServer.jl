module DiffFusionServer

using DiffFusion
using Distributed
using HTTP
using JSON3
using OrderedCollections
using Sockets

include("client/Requests.jl")

# server configurations
include("server/Config.jl")
include("server/Errors.jl")
include("server/Info.jl")
include("server/Options.jl")
include("server/Repository.jl")
include("server/Utils.jl")

# server handlers and router
include("server/Infos.jl")
include("server/Gets.jl")
include("server/Posts.jl")
include("server/Deletes.jl")
include("server/Router.jl")

end

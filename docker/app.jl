# We need to make sure we have all required modules available
try
    using ArgParse
    using DiffFusionServer
    using HTTP
    using Sockets
    @info "Modules loaded successfully."
catch
    @warn "Cannot load modules in current environment. Try activating the current directory."
    using Pkg
    Pkg.activate(".")
    try
        using ArgParse
        using DiffFusionServer
        using HTTP
        using Sockets            
        @info "Modules loaded successfully."
    catch
        @warn "Cannot load modules in current environment. Try installing required packages."
        Pkg.add("ArgParse")
        Pkg.add("HTTP")
        Pkg.add("Sockets")
        Pkg.add(url="https://github.com/frame-consulting/DiffFusionServer.jl")
        #        
        using ArgParse
        using DiffFusionServer
        using HTTP
        using Sockets            
        @info "Modules loaded successfully."
    end
end

s = ArgParseSettings()
@add_arg_table! s begin
    "--host"
        help = "Host name or IP"
        default = "0.0.0.0"
    "--port"
        help = "Port number"
        arg_type = Int
        default = DiffFusionServer._DEFAULT_PORT
end

# get actual arguments
parsed_args = parse_args(ARGS, s)
host = getaddrinfo(parsed_args["host"])
port = parsed_args["port"]
@assert port > 0

# start server
(router, dict) = DiffFusionServer.router()
server = HTTP.serve(router, host, port)

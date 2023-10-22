
using DiffFusionServer
using HTTP
using JSON3
using OrderedCollections
using Sockets
using Test

@testset "Test router." begin
    router = DiffFusionServer.router().router
    server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
    #
    resp = HTTP.get("http://localhost:2024/api/v1/info")
    body = JSON3.read(resp.body)
    # println(body)
    @test body == DiffFusionServer._INFO_STRING
    resp = HTTP.get("http://localhost:2024/api/v1/aliases")
    body = JSON3.read(resp.body)
    # println(typeof(body))
    @test body == [ key for key in keys(DiffFusionServer.initial_repository()) ]
    #
    resp = HTTP.get("http://localhost:2024/api/v1", status_exception=false)
    # println(resp.status)
    @test resp.status == 404
    # close the server which will stop the HTTP server from listening
    close(server)
    @test istaskdone(server.task)
end



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
    body = String(resp.body)
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

@testset "Test errors." begin
    router = DiffFusionServer.router().router
    server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
    #
    headers = [ ]
    resp = HTTP.get("http://localhost:2024/api/v1/ops", headers, status_exception=false)
    @test resp.status == 211
    #
    headers = [ "alias" => "Std" ]
    resp = HTTP.get("http://localhost:2024/api/v1/ops", headers, status_exception=false)
    @test resp.status == 212
    #
    headers = [ "op" => "nothing", "alias" => "Std", ]
    body = OrderedDict{String, Any}(
        "alias" => "Std",
        "ts" => OrderedDict{String, Any}(
            "alias" => "ts/Std",
            "times" => [ 0.0, 1.0, 2.0 ],
            "values" => [ 0.5, 0.6, 0.7 ],
        )
    )
    resp = HTTP.post(
        "http://localhost:2024/api/v1/ops",
        headers,
        JSON3.write(body),
        status_exception=false,
    )
    @test resp.status == 213
    #
    headers = [ "op" => "build", "alias" => "Std", ]
    body = OrderedDict{String, Any}(
        "typename" => "DiffFusion.FlatForward",
        "constructor" => "FlatForward",
        "alias" => "Std",
    )
    resp = HTTP.post(
        "http://localhost:2024/api/v1/ops",
        headers,
        JSON3.write(body),
        status_exception=false,
    )
    @test resp.status == 216
    #
    headers = [  ]
    resp = HTTP.delete("http://localhost:2024/api/v1/ops", headers, status_exception=false)
    @test resp.status == 211
    #
    headers = [ "alias" => "Std", ]
    resp = HTTP.delete("http://localhost:2024/api/v1/ops", headers, status_exception=false)
    @test resp.status == 212
    #
    headers = [  ]
    resp = HTTP.get("http://localhost:2024/api/v1/bulk", headers, JSON3.write("No List"), status_exception=false)
    @test resp.status == 219
    #
    headers = [  ]
    resp = HTTP.get("http://localhost:2024/api/v1/bulk", headers, JSON3.write(["No", "Alias"]), status_exception=false)
    @test resp.status == 212
    #
    headers = [  ]
    resp = HTTP.get("http://localhost:2024/api/v1/bulk", headers, JSON3.write(["true", "false"]), status_exception=false)
    @test resp.status == 211
    #
    headers = [ "op" => "copy", ]
    resp = HTTP.get("http://localhost:2024/api/v1/bulk", headers, JSON3.write(["SobolBrownianIncrements", "false"]), status_exception=false)
    @test resp.status == 218
    #
    headers = [  ]
    resp = HTTP.post("http://localhost:2024/api/v1/bulk", headers, JSON3.write("No List"), status_exception=false)
    @test resp.status == 219
    #
    headers = [  ]
    resp = HTTP.post("http://localhost:2024/api/v1/bulk", headers, JSON3.write(["No", "Elem", "List"]), status_exception=false)
    @test resp.status == 220
    #
    headers = [  ]
    resp = HTTP.post("http://localhost:2024/api/v1/bulk", headers, JSON3.write([[1, 2, 3], "Elem", "List"]), status_exception=false)
    @test resp.status == 220
    #
    headers = [  ]
    resp = HTTP.post("http://localhost:2024/api/v1/bulk", headers, JSON3.write([[1, 2, ], [1, 2, ]]), status_exception=false)
    @test resp.status == 211
    #
    headers = [ "op" => "Somethingelse", ]
    resp = HTTP.post("http://localhost:2024/api/v1/bulk", headers, JSON3.write([[1, 2, ], [1, 2, ]]), status_exception=false)
    @test resp.status == 213
    # close the server which will stop the HTTP server from listening
    close(server)
    @assert istaskdone(server.task)
end


@testset "Test operations." begin
    router = DiffFusionServer.router().router
    server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
    #
    headers = [ "op" => "copy", "alias" => "Std", ]
    body = OrderedDict{String, Any}(
        "alias" => "Std",
        "ts" => OrderedDict{String, Any}(
            "alias" => "ts/Std",
            "times" => [ 0.0, 1.0, 2.0 ],
            "values" => [ 0.5, 0.6, 0.7 ],
        )
    )
    resp = HTTP.post(
        "http://localhost:2024/api/v1/ops",
        headers,
        JSON3.write(body),
    )
    @test JSON3.read(resp.body) == "Store OrderedDict with alias Std."
    #
    headers = [ "op" => "build", "alias" => "ts/EUR", ]
    body = OrderedDict{String, Any}(
       "typename" => "DiffFusion.FlatForward",
       "constructor" => "FlatForward",
        "alias" => "ts/EUR",
        "rate" => 0.0316,
    )
    resp = HTTP.post(
        "http://localhost:2024/api/v1/ops",
        headers,
        JSON3.write(body),
    )
    @test JSON3.read(resp.body) == "Store object with alias ts/EUR and type DiffFusion.FlatForward."
    #
    resp = HTTP.get("http://localhost:2024/api/v1/aliases")
    body = JSON3.read(resp.body)
    keys_ = vcat(
        [ key for key in keys(DiffFusionServer.initial_repository()) ],
        ["Std", "ts/EUR"],
    )
    @test length(body) == length(keys_)
    for k in body
        @test k in keys_
    end
    #
    headers = [ "alias" => "Std", ]
    resp = HTTP.delete("http://localhost:2024/api/v1/ops", headers)
    @test JSON3.read(resp.body) == "Deleted object with alias Std and object type OrderedDict{String, Any}."
    #
    resp = HTTP.get("http://localhost:2024/api/v1/aliases")
    body = JSON3.read(resp.body)
    keys_ = vcat(
        [ key for key in keys(DiffFusionServer.initial_repository()) ],
        [ "ts/EUR"],
    )
    @test length(body) == length(keys_)
    for k in body
        @test k in keys_
    end
    #
    # close the server which will stop the HTTP server from listening
    close(server)
    @assert istaskdone(server.task)
end


@testset "Test bulk operations." begin
    router = DiffFusionServer.router().router
    server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
    #
    headers = [ "op" => "copy",]
    body = [
        ["yts/1", OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "FlatForward",
             "alias" => "ts/EUR",
             "rate" => 0.01,
        )],
        ["yts/2", OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "FlatForward",
             "alias" => "ts/EUR",
             "rate" => 0.02,
        )],
    ]
    resp = HTTP.post(
        "http://localhost:2024/api/v1/bulk",
        headers,
        JSON3.write(body),
    )
    @test resp.status == 200
    @test JSON3.read(resp.body) == [
        "Store OrderedDict with alias yts/1.",
        "Store OrderedDict with alias yts/2."
    ]
    #
    headers = [ "op" => "build",]
    body = [
        ["yts/1", OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "FlatForward",
             "alias" => "ts/EUR",
             "rate" => 0.01,
        )],
        ["yts/2", OrderedDict{String, Any}(
            "typename" => "DiffFusion.FlatForward",
            "constructor" => "FlatForward",
             "alias" => "ts/EUR",
             "rate" => 0.02,
        )],
    ]
    resp = HTTP.post(
        "http://localhost:2024/api/v1/bulk",
        headers,
        JSON3.write(body),
    )
    @test resp.status == 200
    @test JSON3.read(resp.body) == [
        "Store object with alias yts/1 and type DiffFusion.FlatForward.",
        "Store object with alias yts/2 and type DiffFusion.FlatForward."
    ]
    #
    headers = [ "op" => "copy",]
    body = [ "yts/1", "yts/2" ]
    resp = HTTP.get(
        "http://localhost:2024/api/v1/bulk",
        headers,
        JSON3.write(body),
    )
    @test resp.status == 200
    #
    headers = [ "op" => "build",]
    body = [ "yts/1", "yts/2" ]
    resp = HTTP.get(
        "http://localhost:2024/api/v1/bulk",
        headers,
        JSON3.write(body),
    )
    @test resp.status == 200
    #
    # close the server which will stop the HTTP server from listening
    close(server)
    @assert istaskdone(server.task)
end

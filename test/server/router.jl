
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

@testset "Test async build operations." begin
    router = DiffFusionServer.router().router
    server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
    #
    headers = [ "op" => "build_async", "alias" => "ts/EUR", ]
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
    @test JSON3.read(resp.body) == "Store object with alias ts/EUR and type Distributed.Future."
    #
    headers = [ "alias" => "ts/EUR", "op" => "build" ]
    resp = HTTP.get(
        "http://localhost:2024/api/v1/ops",
        headers,
    )
    @test resp.status == 200
    res_dict = JSON3.read(resp.body)
    @test res_dict["typename"] == "DiffFusion.FlatForward"
    @test res_dict["constructor"] == "FlatForward"
    @test res_dict["alias"] == "ts/EUR"
    @test res_dict["rate"] == 0.0316
    #
    headers = [ "op" => "build_async",]
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
        "Store object with alias yts/1 and type Distributed.Future.",
        "Store object with alias yts/2 and type Distributed.Future."
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
    # println(JSON3.read(resp.body))  # this prints the serialised Future
    #
    headers = [ "op" => "build",]
    body = [ "yts/1", "yts/2" ]
    resp = HTTP.get(
        "http://localhost:2024/api/v1/bulk",
        headers,
        JSON3.write(body),
    )
    @test resp.status == 200
    # println(JSON3.read(resp.body))
    # check for expected results
    res_list = JSON3.read(resp.body)
    @test length(res_list) == 2
    @test res_list[1]["typename"] == "DiffFusion.FlatForward"
    @test res_list[1]["constructor"] == "FlatForward"
    @test res_list[1]["alias"] == "ts/EUR"
    @test res_list[1]["rate"] == 0.01
    @test res_list[2]["typename"] == "DiffFusion.FlatForward"
    @test res_list[2]["constructor"] == "FlatForward"
    @test res_list[2]["alias"] == "ts/EUR"
    @test res_list[2]["rate"] == 0.02
    #
    # close the server which will stop the HTTP server from listening
    close(server)
    @assert istaskdone(server.task)
end


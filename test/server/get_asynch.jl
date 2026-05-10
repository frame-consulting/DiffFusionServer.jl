
using DiffFusionServer
using HTTP
using JSON3
using OrderedCollections
using Sockets
using Test

@testset "Asynchronous get for long-running calculations" begin
    
        (router, repository) = DiffFusionServer.router()
        server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
        endpoint = "http://localhost:2024/api/v1/ops"
        json_string = """
            {
                "typename" : "Nothing",
                "constructor" : "later",
                "seconds" : 1
            }
        """

        @testset "Wait while post on later call" begin
            #
            headers = [ "op" => "build", "alias" => "later/build/1", ]
            run_time = @elapsed begin
                resp = HTTP.post(endpoint, headers, json_string)
            end
            #
            @test run_time > 1.0
            @test resp.status == DiffFusionServer._NO_HTTP_ERROR
            println(JSON3.read(resp.body))
        end

        @testset "Do not wait while async build on later call" begin
            #
            headers = [ "op" => "build_async", "alias" => "later/build_async/1", ]
            run_time = @elapsed begin
                resp = HTTP.post(endpoint, headers, json_string)
            end
            #
            @test run_time < 1.0
            @test resp.status == DiffFusionServer._NO_HTTP_ERROR
            println(JSON3.read(resp.body))
        end

        @testset "No need to wait on get" begin
            #
            headers = [ "op" => "build", "alias" => "later/build/1", ]
            resp = HTTP.post(endpoint, headers, json_string)
            #
            headers = [ "op" => "build", "alias" => "later/build/1", ]
            run_time = @elapsed begin
                resp = HTTP.get(endpoint, headers)
            end
            #
            @test run_time < 0.5
            @test resp.status == DiffFusionServer._NO_HTTP_ERROR
            @test JSON3.read(resp.body) == "nothing"
        end

        @testset "Wait on get for async build" begin
            #
            headers = [ "op" => "build_async", "alias" => "later/build_async/1", ]
            resp = HTTP.post(endpoint, headers, json_string)
            #
            headers = [ "op" => "build", "alias" => "later/build_async/1", ]
            run_time = @elapsed begin
                resp = HTTP.get(endpoint, headers)
            end
            #
            @test run_time > 1.0
            @test resp.status == DiffFusionServer._NO_HTTP_ERROR
            @test JSON3.read(resp.body) == "nothing"
        end

        @testset "Do not wait on async get for async build" begin
            #
            headers = [ "op" => "build_async", "alias" => "later/build_async/1", ]
            resp = HTTP.post(endpoint, headers, json_string)
            #
            headers = [ "op" => "build_async", "alias" => "later/build_async/1", ]
            run_time = @elapsed begin
                resp = HTTP.get(endpoint, headers)
            end
            #
            println(JSON3.read(resp.body))
            @test run_time < 0.5
            @test resp.status == 223
            #
            sleep(1.0)  # make sure Future is ready
            run_time = @elapsed begin
                resp = HTTP.get(endpoint, headers)
            end
            #
            @test run_time < 0.5
            @test resp.status == DiffFusionServer._NO_HTTP_ERROR
            @test JSON3.read(resp.body) == "nothing"
        end

        @testset "Do not wait on copy get for async build" begin
            #
            headers = [ "op" => "build_async", "alias" => "later/build_async/1", ]
            resp = HTTP.post(endpoint, headers, json_string)
            #
            headers = [ "op" => "copy", "alias" => "later/build_async/1", ]
            run_time = @elapsed begin
                resp = HTTP.get(endpoint, headers)
            end
            #
            body = JSON3.read(resp.body)
            @test run_time < 0.5
            @test resp.status == DiffFusionServer._NO_HTTP_ERROR
            @test isa(body, JSON3.Object)
            for key in keys(body)
                @test key in (:where, :whence, :id, :lock, :v,)
            end
        end

        close(server)
        @test istaskdone(server.task)

end
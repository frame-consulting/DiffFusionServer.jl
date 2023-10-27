
using DiffFusionServer
using HTTP
using JSON3
using OrderedCollections
using Sockets
using Test

@testset "Test simulation example" begin

    file_name = joinpath(@__DIR__, "../json/model_objects.json")
    model_json = JSON3.read(read(file_name, String))

    file_name = joinpath(@__DIR__, "../json/instrument_objects.json")
    instrument_json = JSON3.read(read(file_name, String))


    @testset "Test individual copy requests" begin
        router = DiffFusionServer.router().router
        server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
        #
        for d in model_json
            headers = [ "op" => "copy", "alias" => d["alias"], ]
            resp = HTTP.post(
                "http://localhost:2024/api/v1/ops",
                headers,
                JSON3.write(d),
            )        
            println(JSON3.read(resp.body))
        end
        for d in instrument_json
            headers = [ "op" => "copy", "alias" => d["alias"], ]
            resp = HTTP.post(
                "http://localhost:2024/api/v1/ops",
                headers,
                JSON3.write(d),
            )        
            println(JSON3.read(resp.body))
        end
        # close the server which will stop the HTTP server from listening
        close(server)
        @test istaskdone(server.task)
    end

    @testset "Test individual build requests" begin
        router = DiffFusionServer.router().router
        server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
        #
        for d in model_json
            headers = [ "op" => "build", "alias" => d["alias"], ]
            resp = HTTP.post(
                "http://localhost:2024/api/v1/ops",
                headers,
                JSON3.write(d),
            )        
            println(JSON3.read(resp.body))
        end
        #
        headers = [ "op" => "build", "alias" => "swap/EUR6M-USD3M-jIKbhm", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/ops",
            headers,
            JSON3.write(instrument_json),
        )
        println(JSON3.read(resp.body))
        # run simulation
        json_string = """
        {
            "typename" : "DiffFusion.Simulation",
            "constructor" : "simple_simulation",
            "model" : "{md/G3}",
            "ch" : "{ch/STD}",
            "times" : [ 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.0 ],
            "n_paths" : 1024,
            "kwargs" :
            {
                "with_progress_bar" : "{true}",
                "brownian_increments" : "{SobolBrownianIncrements}"
            }
        }
        """
        json = JSON3.read(json_string)
        headers = [ "op" => "build", "alias" => "sim/G3-Sobol", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/ops",
            headers,
            JSON3.write(json),
        )        
        println(JSON3.read(resp.body))
        # setup path
        json_string = """
        {
            "typename" : "DiffFusion.Path",
            "constructor" : "path",
            "sim" : "{sim/G3-Sobol}",
            "ts" : [
                "{yc/USD:SOFR}",
                "{yc/USD:LIB3M}",
                "{yc/EUR:ESTR}",
                "{yc/EUR:XCCY}",
                "{yc/EUR:EURIBOR6M}",
                "{yc/GBP:SONIA}",
                "{yc/GBP:XCCY}",
                "{pa/USD:SOFR}",
                "{pa/USD:LIB3M}",
                "{pa/EUR:ESTR}",
                "{pa/EUR:EURIBOR6M}",
                "{pa/GBP:SONIA}",
                "{pa/EUR-USD}",
                "{pa/GBP-USD}",
                "{pa/EUHICP}",
                "{pa/NIK-FUT}"
            ],
            "ctx" : "{ct/STD}",
            "ip" : "{LinearPathInterpolation}"
        }
        """
        json = JSON3.read(json_string)
        headers = [ "op" => "build", "alias" => "path/G3", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/ops",
            headers,
            JSON3.write(json),
        )        
        println(JSON3.read(resp.body))
        # scenarios
        json_string = """
        {
            "typename" : "DiffFusion.ScenarioCube",
            "constructor" : "scenarios",
            "legs" : "{swap/EUR6M-USD3M-jIKbhm}",
            "times" : [ 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.0 ],
            "path" : "{path/G3}",
            "discount_curve_key" : "nothing"
        }
        """
        json = JSON3.read(json_string)
        headers = [ "op" => "build", "alias" => "cube/EUR6M-USD3M-jIKbhm", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/ops",
            headers,
            JSON3.write(json),
        )        
        println(JSON3.read(resp.body))
        # expected exposure
        json_string = """
        {
            "typename" : "DiffFusion.ScenarioCube",
            "constructor" : "expected_exposure",
            "scens" : "{cube/EUR6M-USD3M-jIKbhm}",
            "gross_leg" : "{false}",
            "average_paths" : "{true}",
            "aggregate_legs" : "{true}"
        }
        """
        json = JSON3.read(json_string)
        headers = [ "op" => "build", "alias" => "cube/EUR6M-USD3M-jIKbhm/EE", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/ops",
            headers,
            JSON3.write(json),
        )        
        println(JSON3.read(resp.body))
        #
        headers = [ "op" => "build", "alias" => "cube/EUR6M-USD3M-jIKbhm/EE", ]
        resp = HTTP.get(
            "http://localhost:2024/api/v1/ops",
            headers,
        )
        json = JSON3.read(resp.body)
        println(keys(json))
        println(json.times)
        println(keys(json.X))
        println(json.X.typename)
        println(json.X.constructor)
        println(json.X.dims)
        @test json.X.dims == [1, 9, 1]
        # close the server which will stop the HTTP server from listening
        close(server)
        @test istaskdone(server.task)
    end
    
    @testset "Test bulk copy requests" begin
        router = DiffFusionServer.router().router
        server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
        #
        headers = [ "op" => "COPY", ]
        requests = [
            [d["alias"], d] for d in model_json
        ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/bulk",
            headers,
            JSON3.write(requests),
        )
        println(JSON3.read(resp.body))
        # close the server which will stop the HTTP server from listening
        close(server)
        @test istaskdone(server.task)
    end

    @testset "Test bulk build requests" begin
        router = DiffFusionServer.router().router
        server = HTTP.serve!(router, Sockets.localhost, DiffFusionServer._DEFAULT_PORT)
        #
        headers = [ "op" => "BUILD", ]
        requests = [
            [d["alias"], d] for d in model_json
        ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/bulk",
            headers,
            JSON3.write(requests),
        )
        println(JSON3.read(resp.body))
        #
        headers = [ "op" => "build", "alias" => "swap/EUR6M-USD3M-jIKbhm", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/ops",
            headers,
            JSON3.write(instrument_json),
        )
        println(JSON3.read(resp.body))
        #
        json_string = """
        [
        {
            "typename" : "DiffFusion.Simulation",
            "constructor" : "simple_simulation",
            "model" : "{md/G3}",
            "ch" : "{ch/STD}",
            "times" : [ 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.0 ],
            "n_paths" : 1024,
            "kwargs" :
            {
                "with_progress_bar" : "{true}",
                "brownian_increments" : "{SobolBrownianIncrements}"
            }
        },
        {
            "typename" : "DiffFusion.Path",
            "constructor" : "path",
            "sim" : "{sim/G3-Sobol}",
            "ts" : [
                "{yc/USD:SOFR}",
                "{yc/USD:LIB3M}",
                "{yc/EUR:ESTR}",
                "{yc/EUR:XCCY}",
                "{yc/EUR:EURIBOR6M}",
                "{yc/GBP:SONIA}",
                "{yc/GBP:XCCY}",
                "{pa/USD:SOFR}",
                "{pa/USD:LIB3M}",
                "{pa/EUR:ESTR}",
                "{pa/EUR:EURIBOR6M}",
                "{pa/GBP:SONIA}",
                "{pa/EUR-USD}",
                "{pa/GBP-USD}",
                "{pa/EUHICP}",
                "{pa/NIK-FUT}"
            ],
            "ctx" : "{ct/STD}",
            "ip" : "{LinearPathInterpolation}"
        },
        {
            "typename" : "DiffFusion.ScenarioCube",
            "constructor" : "scenarios",
            "legs" : "{swap/EUR6M-USD3M-jIKbhm}",
            "times" : [ 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.0 ],
            "path" : "{path/G3}",
            "discount_curve_key" : "nothing"
        },
        {
            "typename" : "DiffFusion.ScenarioCube",
            "constructor" : "expected_exposure",
            "scens" : "{cube/EUR6M-USD3M-jIKbhm}",
            "gross_leg" : "{false}",
            "average_paths" : "{true}",
            "aggregate_legs" : "{true}"
        }
        ]
        """
        json = JSON3.read(json_string)
        alias = [
            "sim/G3-Sobol",
            "path/G3",
            "cube/EUR6M-USD3M-jIKbhm",
            "cube/EUR6M-USD3M-jIKbhm/EE",
        ]
        requests = [
            [ a, d ] for (a, d) in zip(alias, json)
        ]
        headers = [ "op" => "BUILD", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/bulk",
            headers,
            JSON3.write(requests),
        )
        println(JSON3.read(resp.body))
        #
        headers = [ "op" => "build", "alias" => "cube/EUR6M-USD3M-jIKbhm/EE", ]
        resp = HTTP.get(
            "http://localhost:2024/api/v1/ops",
            headers,
        )
        json = JSON3.read(resp.body)
        println(keys(json))
        println(json.times)
        println(keys(json.X))
        println(json.X.typename)
        println(json.X.constructor)
        println(json.X.dims)
        @test json.X.dims == [1, 9, 1]
        #
        # close the server which will stop the HTTP server from listening
        close(server)
        @test istaskdone(server.task)
    end

end

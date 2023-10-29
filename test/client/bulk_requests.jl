using DiffFusionServer

using DiffFusion
using HTTP
using JSON3
using OrderedCollections
using Sockets
using Test

@testset "Test API bulkrequests." begin

    (router, repository) = DiffFusionServer.router()
    server = HTTP.serve!(router, Sockets.localhost, 2024)

    @testset "Test model setup." begin
        model_json_string = read(joinpath(@__DIR__, "../json" ,"model_objects.json"), String)
        model_dicts = DiffFusion.serialise(JSON3.read(model_json_string))
        (body, status) = DiffFusionServer.post_bulk([ [d["alias"], d] for d in model_dicts ])
        @test status == DiffFusionServer._NO_HTTP_ERROR
        for m in body
             println(m)
        end
    end

    @testset "Test instrument setup." begin
        instrument_json_string = read(joinpath(@__DIR__, "../json" , "instrument_objects.json"), String)
        instrument_dicts = DiffFusion.serialise(JSON3.read(instrument_json_string))
        (body, status) = DiffFusionServer.post("swap/EUR6M-USD3M-jIKbhm", instrument_dicts)
        @test status == DiffFusionServer._NO_HTTP_ERROR
        println(body)
    end

    @testset "Test bulk simulation." begin
        bulk_data =[
            ["sim/G3-Sobol", OrderedDict(
                "typename" => "DiffFusion.Simulation",
                "constructor" => "simple_simulation",
                "model" => "{md/G3}",
                "ch" => "{ch/STD}",
                "times" => [ 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.0 ],
                "n_paths" => 2^10,
                "kwargs" => OrderedDict(
                    "with_progress_bar" => "{true}",
                    "brownian_increments" => "{SobolBrownianIncrements}",
                ),
            )],
            ["path/G3", OrderedDict(
                "typename" => "DiffFusion.Path",
                "constructor" => "path",
                "sim" => "{sim/G3-Sobol}",
                "ts" => [
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
                    "{pa/NIK-FUT}",
                ],
                "ctx" => "{ct/STD}",
                "ip" => "{LinearPathInterpolation}",            
            )],
            ["cube/EUR6M-USD3M-jIKbhm", OrderedDict(
                "typename" => "DiffFusion.ScenarioCube",
                "constructor" => "scenarios",
                "legs" => "{swap/EUR6M-USD3M-jIKbhm}",
                "times" => [ 0.00, 0.25, 0.50, 0.75, 1.00, 1.25, 1.50, 1.75, 2.0 ],
                "path" => "{path/G3}",
                "discount_curve_key" => "nothing",            
            )],
            ["cube/EUR6M-USD3M-jIKbhm/EE", OrderedDict(
                "typename" => "DiffFusion.ScenarioCube",
                "constructor" => "expected_exposure",
                "scens" => "{cube/EUR6M-USD3M-jIKbhm}",
                "gross_leg" => "{false}",
                "average_paths" => "{true}",
                "aggregate_legs" => "{true}",            
            )]
        ]
        (body, status) = DiffFusionServer.post_bulk(bulk_data)
        @test status == DiffFusionServer._NO_HTTP_ERROR        
        for m in body
             println(m)
        end
    end

    @testset "Test bulk objet retrieval" begin
        aliases = ["cube/EUR6M-USD3M-jIKbhm", "cube/EUR6M-USD3M-jIKbhm/EE"]
        (body, status) = DiffFusionServer.get_bulk(aliases)
        @test status == DiffFusionServer._NO_HTTP_ERROR
        for m in body
             println(keys(m))
             println(m.X.dims)
             println(m.leg_aliases)
        end
    end

    # close the server which will stop the HTTP server from listening
    close(server)
    @assert istaskdone(server.task)

end
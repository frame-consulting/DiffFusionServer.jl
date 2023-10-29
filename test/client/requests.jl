
using DiffFusionServer

using DiffFusion
using HTTP
using JSON3
using OrderedCollections
using Sockets
using Test

@testset "Test API requests." begin

    (router, repository) = DiffFusionServer.router()
    server = HTTP.serve!(router, Sockets.localhost, 2024)

    @testset "Test initial repository." begin
        (body, status) = DiffFusionServer.info()
        @test body == DiffFusionServer._INFO_STRING
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        (body, status) = DiffFusionServer.aliases()
        @test body == [ key for key in keys(DiffFusionServer.initial_repository()) ]
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        (body, status) = DiffFusionServer.get("Std")
        @test status == 212
        #
        (body, status) = DiffFusionServer.delete("Std")
        @test status == 212
        #
        (body, status) = DiffFusionServer.post("Std", "Hello World.")
        @test body == "Store object with alias Std and type String."
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        # println(repository)
        r_ref = DiffFusionServer.initial_repository()
        r_ref["Std"] = "Hello World."
        @test repository == r_ref
    end
   
    @testset "Test G3 example." begin
        example_dicts = DiffFusion.Examples.load(DiffFusion.Examples.examples[1])
        for d in example_dicts
            #println(d["alias"])
            (body, status) = DiffFusionServer.post(d["alias"], d)
            println(body)
            @test status == DiffFusionServer._NO_HTTP_ERROR
        end
    end

    @testset "Test G3 simulation." begin
        simulation = OrderedDict{String, Any}(
            "typename" => "DiffFusion.Simulation",
            "constructor" => "simple_simulation",
            "model" => "{md/G3}",
            "ch" => "{ch/STD}",
            "times" => [ 0.0, 2.0, 4.0, 6.0, 8.0, 10.0 ],
            "n_paths" => 2^10,
        )
        (body, status) = DiffFusionServer.post("sim/G3", simulation)
        println(body)
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        simulation = OrderedDict{String, Any}(
            "typename" => "DiffFusion.Simulation",
            "constructor" => "simple_simulation",
            "model" => "{md/G3}",
            "ch" => "{ch/STD}",
            "times" => [ 0.0, 2.0, 4.0, 6.0, 8.0, 10.0 ],
            "n_paths" => 2^10,
            "kwargs" => OrderedDict{String, Any}(
                "with_progress_bar" => "{true}",
                "brownian_increments" => "{SobolBrownianIncrements}",
            ),
        )
        #obj = DiffFusion.deserialise(simulation, repository)
        (body, status) = DiffFusionServer.post("sim/G3-Sobol", simulation)
        println(body)
        @test status == DiffFusionServer._NO_HTTP_ERROR
    end

    # allow re-using swap alias(es)
    local swap_alias

    @testset "Test swap setup." begin
        serialised_example = DiffFusion.Examples.load(DiffFusion.Examples.examples[1])
        example = DiffFusion.Examples.build(serialised_example)
        swap = DiffFusion.Examples.random_swap(example, "USD")
        @assert length(swap) == 2
        swap_alias = DiffFusion.alias(swap[1])[begin:end-2]
        (body, status) = DiffFusionServer.post("swap/" * swap_alias, swap)
        println(body)
        @test status == DiffFusionServer._NO_HTTP_ERROR
    end

    @testset "Test path setup." begin
        path = OrderedDict{String, Any}(
            "typename" => "DiffFusion.Path",
            "constructor" => "path",
            "sim" => "{sim/G3}",
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
        )
        (body, status) = DiffFusionServer.post("path/G3", path)
        println(body)
        @test status == DiffFusionServer._NO_HTTP_ERROR
    end

    @testset "Test scenario pricing." begin
        cube = OrderedDict{String, Any}(
            "typename" => "DiffFusion.ScenarioCube",
            "constructor" => "scenarios",
            "legs" => "{swap/" * swap_alias * "}",
            "times" => [ 0.0, 2.0, 4.0, 6.0, 8.0, 10.0 ],
            "path" => "{path/G3}",
            "discount_curve_key" => "nothing",
        )
        (body, status) = DiffFusionServer.post("cube/" * swap_alias, cube)
        println(body)
        @test status == DiffFusionServer._NO_HTTP_ERROR
    end

    @testset "Test expected exposure calculation." begin
        cube = OrderedDict{String, Any}(
            "typename" => "DiffFusion.ScenarioCube",
            "constructor" => "expected_exposure",
            "scens" => "{cube/" * swap_alias *"}",
            "gross_leg" => "{false}",
            "average_paths" => "{true}",
            "aggregate_legs" => "{true}",
        )
        (body, status) = DiffFusionServer.post("cube/" * swap_alias * "/EE", cube)
        println(body)
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        cube = OrderedDict{String, Any}(
            "typename" => "DiffFusion.ScenarioCube",
            "constructor" => "expected_exposure",
            "scens" => "{cube/" * swap_alias *"}",
            "gross_leg" => "{false}",
            "average_paths" => "{true}",
            "aggregate_legs" => "{false}",
        )
        (body, status) = DiffFusionServer.post("cube/" * swap_alias * "/EE-ATTR", cube)
        println(body)
        @test status == DiffFusionServer._NO_HTTP_ERROR
    end

    @testset "Test result retrieval." begin
        (body, status) = DiffFusionServer.get("cube/" * swap_alias * "/EE", "COPY")
        @test size(body.X) == (6,)
        @test body.times == [ 0, 2, 4, 6, 8, 10 ]
        @test body.leg_aliases == [ "EE[" * swap_alias * "-1]_EE[" * swap_alias * "-2]" ]
        @test body.numeraire_context_key == "USD"
        @test body.discount_curve_key == nothing
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        (body, status) = DiffFusionServer.get("cube/" * swap_alias * "/EE", "BUILD")
        @test size(body.X.data) == (6,)
        @test body.X.dims == [ 1, 6, 1, ]
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        (body, status) = DiffFusionServer.get("cube/" * swap_alias * "/EE-ATTR", "BUILD")
        @test size(body.X.data) == (12,)
        @test body.X.dims == [ 1, 6, 2, ]
        @test status == DiffFusionServer._NO_HTTP_ERROR
        #
        (body, status) = DiffFusionServer.get("cube/" * swap_alias, "BUILD")
        @test size(body.X.data) == (12288,)
        @test body.X.dims == [1024, 6, 2]
        @test status == DiffFusionServer._NO_HTTP_ERROR
    end

    # close the server which will stop the HTTP server from listening
    close(server)
    @assert istaskdone(server.task)
    
end
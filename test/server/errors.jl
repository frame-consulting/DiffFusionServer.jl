
using DiffFusionServer
using HTTP
using JSON3
using OrderedCollections
using Sockets
using Test


@testset "Test error handling" begin

    @testset "Test error functions." begin
        resp = DiffFusionServer._error_key_not_found("key")
        @test resp.status == 211
        #
        resp = DiffFusionServer._error_alias_not_found("alias")
        @test resp.status == 212
        #
        resp = DiffFusionServer._error_operation_not_implemented("operation")
        @test resp.status == 213
        #
        struct NoException <: Exception end
        #
        resp = DiffFusionServer._error_create_json_fail("alias", NoException())
        @test resp.status == 214
        #
        resp = DiffFusionServer._error_create_ordered_dict_fail("alias", NoException())
        @test resp.status == 215
        #
        resp = DiffFusionServer._error_build_object_fail("alias", NoException())
        @test resp.status == 216
        #
        resp = DiffFusionServer._error_object_serialisation_fail("alias", NoException())
        @test resp.status == 217
        #
        resp = DiffFusionServer._error_create_json_string_fail("alias", NoException())
        @test resp.status == 218
        #
        resp = DiffFusionServer._error_bulk_list_not_found("body")
        @test resp.status == 219
        #
        resp = DiffFusionServer._error_bulk_element_list_not_found("elem")
        @test resp.status == 220

        # resp = DiffFusionServer._er
    end


    @testset "Test server errors." begin
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
        headers = [ "op" => "COPY", "alias" => "Std", ]
        resp = HTTP.post(
            "http://localhost:2024/api/v1/ops",
            headers,
            "Some text",
            status_exception=false,
        )
        @test resp.status == 214
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
    

end

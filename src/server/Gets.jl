
"""
    api_get(
        request::HTTP.Request,
        repository::AbstractDict,
        options::Options,
        )

Return the object with requested alias header field in body of response.

This operation does not modify the server repository.

Request header must contain fields 'alias' and 'op'. The value of field
'alias' is the object alias of requested object in the server
repository. Value of field 'op' is 'COPY' or 'BUILD'.

For COPY operation, the requested data is directly written to JSON format.

For BUILD operation, the requested data is first serialised using DiffFusion
serialise operation. Then the serialised object is written to JSON format.

The resulting JSON object is returned via the response body.
"""
function api_get(
    request::HTTP.Request,
    repository::AbstractDict,
    options::Options,
    )
    #
    res = _check_for_header_field(request, "alias")
    if isa(res, HTTP.Message)
        return res
    end
    res = _check_for_alias_in_repository(res, repository)
    if isa(res, HTTP.Message)
        return res
    end
    alias = res
    res = _check_for_header_field(request, "op")
    if isa(res, HTTP.Message)
        return res
    end
    op = uppercase(res)
    if !(op in _OPERATIONS)
        return _error_operation_not_implemented(op)
    end
    obj = repository[alias]
    local out_obj
    if op==_BUILD_OP
        try
            out_obj = DiffFusion.serialise(obj)
        catch e
            return _error_object_serialisation_fail(alias, e)
        end
    else
        out_obj = obj
    end
    local json3_string
    try
        json3_string = JSON3.write(out_obj)
    catch e
        return _error_create_json_string_fail(alias, e)
    end
    # finally return object...
    return HTTP.Response(_NO_HTTP_ERROR, json3_string)
end


"""
    api_bulk_get(
        request::HTTP.Request,
        repository::AbstractDict,
        options::Options,
        )

Return a list of objects for a list of aliases.

This operation does not modify the server repository.

Request header must contain field 'op'. Value of field 'op' is
'COPY' or 'BUILD'.

Request body must contain a list of 'alias'. The list of 'alias'
is iterated. For each 'alias' the corresponding object is retrieved
from the server repository.

Handling of each individual object follows method `api_get`.

The result is a `Vector` of objects. This result is written to
JSON and returned via the response body.
"""
function api_bulk_get(
    request::HTTP.Request,
    repository::AbstractDict,
    options::Options,
    )
    # we need to retrieve the list of alias from the request body
    local json3_obj
    try
        json3_obj = JSON3.read(request.body)
    catch e
        return _error_create_json_fail(alias, e)
    end
    if !isa(json3_obj, AbstractVector)
        return _error_bulk_list_not_found(json3_obj)
    end
    for alias in json3_obj
        res = _check_for_alias_in_repository(alias, repository)
        if isa(res, HTTP.Message)
            return res
        end
    end
    #
    res = _check_for_header_field(request, "op")
    if isa(res, HTTP.Message)
        return res
    end
    op = uppercase(res)
    if !(op in _OPERATIONS)
        return _error_operation_not_implemented(op)
    end
    res_list = []
    for alias in json3_obj
        obj = repository[alias]
        local out_obj
        if op==_BUILD_OP
            try
                out_obj = DiffFusion.serialise(obj)
            catch e
                return _error_object_serialisation_fail(alias, e)
            end
        else
            out_obj = obj
        end
        res_list = vcat(res_list, [out_obj])
    end
    #
    local json3_string
    try
        json3_string = JSON3.write(res_list)
    catch e
        return _error_create_json_string_fail("[]", e)
    end
     # finally return objects...
     return HTTP.Response(_NO_HTTP_ERROR, json3_string)
end


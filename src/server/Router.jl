
"""
    api_get_info(req::HTTP.Request)

Return an info string about the API as response.
"""
function api_get_info(req::HTTP.Request)
    return HTTP.Response(_NO_HTTP_ERROR, _INFO_STRING)
end


"""
    api_get_aliases(req::HTTP.Request, d::AbstractDict)

Return all aliases from the repository in body of response.
"""
function api_get_aliases(req::HTTP.Request, d::AbstractDict)
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(keys(d)))
end


"""
    api_post(req::HTTP.Request, d::AbstractDict)

Create and store an object for a given alias.

Request header must contain fields 'alias' and 'op'. The value of field
'alias' is the object alias used to store the object in the server
repository. Value of field 'op' is 'COPY' or 'BUILD'.

Request body must be a JSON representation. The data is normalised by
first applying a serialise operation.

For COPY operation, the normalised data is directly stored in the
server repository.

For BUILD operation, the normalised data is deserialised via
DiffFusion operations. The result is the stored in the server repository.
"""
function api_post(req::HTTP.Request, d::AbstractDict)
    res = _check_for_header_field(req, "alias")
    if isa(res, HTTP.Message)
        return res
    end
    alias = res
    res = _check_for_header_field(req, "op")
    if isa(res, HTTP.Message)
        return res
    end
    op = uppercase(res)
    if !(op in _OPERATIONS)
        return _error_operation_not_implemented(op)
    end
    local json3_obj
    try
        json3_obj = JSON3.read(req.body)
    catch e
        return _error_create_json_fail(alias, e)
    end
    local dict_obj
    try
        dict_obj = DiffFusion.serialise(json3_obj)
    catch e
        return _error_create_ordered_dict_fail(alias, e)
    end
    if op==_COPY_OP
        d[alias] = dict_obj
        msg = "Store OrderedDict with alias " * alias * "."
        return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg))
    end
    if op==_BUILD_OP
        local obj
        try
            obj = DiffFusion.deserialise(dict_obj, d)
        catch e
            return _error_build_object_fail(alias, e)
        end
        # finally store object...
        d[alias] = obj
        # println(obj)
        msg = "Store object with alias " * alias * " and type " * string(typeof(obj)) * "."
        return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg))
    end
    if op==_BUILD_ASYNC_OP
        local obj
        try
            obj = remotecall(DiffFusion.deserialise, workers()[begin], dict_obj, d)
        catch e
            return _error_build_async_fail(alias, e)
        end
        # finally store object...
        d[alias] = obj
        # println(obj)
        msg = "Store object with alias " * alias * " and type " * string(typeof(obj)) * "."
        return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg))
    end

end


"""
    api_get(req::HTTP.Request, d::AbstractDict)

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
function api_get(req::HTTP.Request, d::AbstractDict)
    res = _check_for_header_field(req, "alias")
    if isa(res, HTTP.Message)
        return res
    end
    res = _check_for_alias_in_repository(res, d)
    if isa(res, HTTP.Message)
        return res
    end
    alias = res
    res = _check_for_header_field(req, "op")
    if isa(res, HTTP.Message)
        return res
    end
    op = uppercase(res)
    if !(op in _OPERATIONS)
        return _error_operation_not_implemented(op)
    end
    obj = d[alias]
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
    api_delete(req::HTTP.Request, d::AbstractDict)

Delete an object from repository.

Request header must contain field 'alias'. The value of field
'alias' is the object alias of requested object in the server
repository.
"""
function api_delete(req::HTTP.Request, d::AbstractDict)
    res = _check_for_header_field(req, "alias")
    if isa(res, HTTP.Message)
        return res
    end
    res = _check_for_alias_in_repository(res, d)
    if isa(res, HTTP.Message)
        return res
    end
    alias = res
    obj_type = string(typeof(d[alias]))
    delete!(d, alias)
    msg = "Deleted object with alias " * alias * " and object type " * obj_type * "."
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg))
end


"""
    api_bulk_get(req::HTTP.Request, d::AbstractDict)

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
function api_bulk_get(req::HTTP.Request, d::AbstractDict)
    # we need to retrieve the list of alias from the request body
    local json3_obj
    try
        json3_obj = JSON3.read(req.body)
    catch e
        return _error_create_json_fail(alias, e)
    end
    if !isa(json3_obj, AbstractVector)
        return _error_bulk_list_not_found(json3_obj)
    end
    for alias in json3_obj
        res = _check_for_alias_in_repository(alias, d)
        if isa(res, HTTP.Message)
            return res
        end
    end
    #
    res = _check_for_header_field(req, "op")
    if isa(res, HTTP.Message)
        return res
    end
    op = uppercase(res)
    if !(op in _OPERATIONS)
        return _error_operation_not_implemented(op)
    end
    res_list = []
    for alias in json3_obj
        obj = d[alias]
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


"""
    api_bulk_post(req::HTTP.Request, d::AbstractDict)

Create and store a list of objects for a list of aliases.

Request header must contain field 'op'. Value of field 'op' is
'COPY' or 'BUILD'.

Request body must be a JSON representation. The JSON object must
be of the form

    [
        [alias_1, obj_1],
        [alias_2, obj_2],
        ...
    ]

The elements `alias_k`, represent the object aliases used to store the
object in the server repository.

The elements `obj_k` are processed according to COPY or BUILD operation
and following the methodology in `api_post`.
"""
function api_bulk_post(req::HTTP.Request, d::AbstractDict)
    # we need to retrieve the list of [alias, object] from the request body
    local json3_obj
    try
        json3_obj = JSON3.read(req.body)
    catch e
        return _error_create_json_fail(alias, e)
    end
    if !isa(json3_obj, AbstractVector)
        return _error_bulk_list_not_found(json3_obj)
    end
    for elem in json3_obj
        if (!isa(elem, AbstractVector)) || (length(elem)!=2)
            return _error_bulk_element_list_not_found(elem)
        end
        # now we should have something like [alias, obj]
    end
    res = _check_for_header_field(req, "op")
    if isa(res, HTTP.Message)
        return res
    end
    op = uppercase(res)
    if !(op in _OPERATIONS)
        return _error_operation_not_implemented(op)
    end
    msg_list = []
    for elem in json3_obj
        alias = string(elem[1])
        json_obj_elem = elem[2]
        local dict_obj
        try
            dict_obj = DiffFusion.serialise(json_obj_elem)
        catch e
            return _error_create_ordered_dict_fail(alias, e)
        end
        if op==_COPY_OP
            d[alias] = dict_obj
            msg = "Store OrderedDict with alias " * alias * "."
            msg_list = vcat(msg_list, [msg])
        end
        if op==_BUILD_OP
            local obj
            try
                obj = DiffFusion.deserialise(dict_obj, d)
            catch e
                return _error_build_object_fail(alias, e)
            end
            # finally store object...
            d[alias] = obj
            msg = "Store object with alias " * alias * " and type " * string(typeof(obj)) * "."
            msg_list = vcat(msg_list, [msg])
        end
        if op==_BUILD_ASYNC_OP
            local obj
            try
                obj = remotecall(DiffFusion.deserialise, workers()[begin], dict_obj, d)
            catch e
                return _error_build_async_fail(alias, e)
            end
            # finally store object...
            d[alias] = obj
            msg = "Store object with alias " * alias * " and type " * string(typeof(obj)) * "."
            msg_list = vcat(msg_list, [msg])
        end
    end
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg_list))
end

"""
    router(
        api_path = _DEFAULT_API_PATH,
        api_version = _DEFAULT_API_VERSION,
        )

Create a handler function `router` and an initial server repository `repository`
for that `router`. The function returns the named tuple

    (router, repository)

The `router` is configured to accept requests for the specified end points. Requests
are passed on to the corresponding API functions for processing.

The `router` represents a `Handler` function which is typically used in
`HTTP.serve(...)`.

The `repository` is a reference to the object repository. The object repository is
queried and modified by subsequent requests. The current state of the object repository
can be viewed (and modified) by means of the `repository` object reference.
"""
function router(
    api_path = _DEFAULT_API_PATH,
    api_version = _DEFAULT_API_VERSION,
    )
    d = initial_repository()
    r = HTTP.Router()
    # we need to link the repository to the handler functions
    _get_aliases(req::HTTP.Request) = api_get_aliases(req, d)
    _get(req::HTTP.Request) = api_get(req, d)
    _post(req::HTTP.Request) = api_post(req, d)
    _delete(req::HTTP.Request) = api_delete(req, d)
    _bulk_get(req::HTTP.Request) = api_bulk_get(req, d)
    _bulk_post(req::HTTP.Request) = api_bulk_post(req, d)
    #
    api_prefix = api_path * api_version
    #
    HTTP.register!(r, "GET", api_prefix * _INFO_END_POINT, api_get_info)
    HTTP.register!(r, "GET", api_prefix * _ALIASES_END_POINT, _get_aliases)
    HTTP.register!(r, "GET", api_prefix * _OPS_END_POINT, _get)
    HTTP.register!(r, "POST", api_prefix * _OPS_END_POINT, _post)
    HTTP.register!(r, "DELETE", api_prefix * _OPS_END_POINT, _delete)
    HTTP.register!(r, "GET", api_prefix * _BULK_OPS_END_POINT, _bulk_get)
    HTTP.register!(r, "POST", api_prefix * _BULK_OPS_END_POINT, _bulk_post)
    #
    return (router=r, repository=d)
end


"""
    api_post(
        request::HTTP.Request,
        repository::AbstractDict,
        options::Options,
        )

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
function api_post(
    request::HTTP.Request,
    repository::AbstractDict,
    options::Options,
    )
    #
    if options.is_busy
        return _error_server_is_busy()
    end
    #
    res = _check_for_header_field(request, "alias")
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
    local json3_obj
    try
        json3_obj = JSON3.read(request.body)
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
        repository[alias] = dict_obj
        msg = "Store OrderedDict with alias " * alias * "."
        return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg))
    end
    local obj
    if op==_BUILD_OP
        try
            obj = DiffFusion.deserialise(dict_obj, repository)
        catch e
            return _error_build_object_fail(alias, e)
        end
    end
    if op==_BUILD_ASYNC_OP
        try
            obj = remotecall(DiffFusion.deserialise, workers()[begin], dict_obj, repository)
        catch e
            return _error_build_async_fail(alias, e)
        end
    end
    # finally store object to repository...
    repository[alias] = obj
    msg = "Store object with alias " * alias * " and type " * string(typeof(obj)) * "."
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg))
end


"""
    api_bulk_post(
        request::HTTP.Request,
        repository::AbstractDict,
        options::Options,
        )

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
function api_bulk_post(
    request::HTTP.Request,
    repository::AbstractDict,
    options::Options,
    )
    #
    if options.is_busy
        return _error_server_is_busy()
    end
    # we need to retrieve the list of [alias, object] from the request body
    local json3_obj
    try
        json3_obj = JSON3.read(request.body)
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
    res = _check_for_header_field(request, "op")
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
            repository[alias] = dict_obj
            msg = "Store OrderedDict with alias " * alias * "."
            msg_list = vcat(msg_list, [msg])
            continue # short-cut
        end
        local obj
        if op==_BUILD_OP
            try
                obj = DiffFusion.deserialise(dict_obj, repository)
            catch e
                return _error_build_object_fail(alias, e)
            end
        end
        if op==_BUILD_ASYNC_OP
            try
                obj = remotecall(DiffFusion.deserialise, workers()[begin], dict_obj, repository)
            catch e
                return _error_build_async_fail(alias, e)
            end
        end
        # finally store object to repository...
        repository[alias] = obj
        msg = "Store object with alias " * alias * " and type " * string(typeof(obj)) * "."
        msg_list = vcat(msg_list, [msg])
    end
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg_list))
end

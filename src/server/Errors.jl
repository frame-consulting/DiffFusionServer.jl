
"""
    const _NO_HTTP_ERROR

Default return status code.
"""
const _NO_HTTP_ERROR = 200

"""
    _error_key_not_found(key::AbstractString)

Create error response for missing http header key.
"""
function _error_key_not_found(key::AbstractString)
    return HTTP.Response(211, JSON3.write("Key " * key * " not found in header."))
end

"""
    _error_alias_not_found(alias::AbstractString)

Create error response for missing alias.
"""
function _error_alias_not_found(alias::AbstractString)
    return HTTP.Response(212, JSON3.write("Alias " * string(alias) * " not found."))
end

"""
    _error_operation_not_implemented(op::AbstractString)

Create error response for unknown server operation in http header.

Allowed operations are COPY and BUILD.
"""
function _error_operation_not_implemented(op::AbstractString)
    HTTP.Response(213, JSON3.write("Operation " * op * " is not implemented."))
end

"""
    _error_create_json_fail(alias::AbstractString, e::Exception)

Create error response for a failing JSON read operation.
"""
function _error_create_json_fail(alias::AbstractString, e::Exception)
    msg = "Cannot create JSON3 object for alias " * alias * ".\n" * string(e)
    return HTTP.Response(214, JSON3.write(msg))
end

"""
    _error_create_ordered_dict_fail(alias::AbstractString, e::Exception)

Create an error response for a failing dictionary setup.

This error may occur during COPY operation.
"""
function _error_create_ordered_dict_fail(alias::AbstractString, e::Exception)
    msg = "Cannot create OrderedDict object for alias " * alias * ".\n" * string(e)
    return HTTP.Response(215, JSON3.write(msg))
end

"""
    _error_build_object_fail(alias::AbstractString, e::Exception)

Create an error response for a failing BUILD operation.

This error indicates a wrong DiffFuion call.
"""
function _error_build_object_fail(alias::AbstractString, e::Exception)
    msg = "Cannot deserialise object for alias " * alias * ".\n" * string(e)
    return HTTP.Response(216, JSON3.write(msg))
end

"""
    _error_object_serialisation_fail(alias::AbstractString, e::Exception)

Create an error response for a failing object serialisation.

This error indicates an unsupported object beeing applied to
DiffFusion's serialisation method.
"""
function _error_object_serialisation_fail(alias::AbstractString, e::Exception)
    msg = "Cannot serialise object with alias " * alias * ".\n" * string(e)
    return HTTP.Response(217, JSON3.write(msg))
end

"""
    _error_create_json_string_fail(alias::AbstractString, e::Exception)

Create an error response for a failing JSON write.
"""
function _error_create_json_string_fail(alias::AbstractString, e::Exception)
    msg = "Cannot create JSON string for object with alias " * alias * ".\n" * string(e)
    return HTTP.Response(218, JSON3.write(msg))
end

"""
    _error_bulk_list_not_found(body::Any)

Create an error response for a missing list for a bulk request.
"""
function _error_bulk_list_not_found(body::Any)
    msg = "Request body is not a list:\n" * string(body)
    return HTTP.Response(219, JSON3.write(msg))
end

"""
    _error_bulk_element_list_not_found(elem::Any)

Create an error response for a missing list containing alias and
request details for usee in bulk request.
"""
function _error_bulk_element_list_not_found(elem::Any)
    msg = "Request body element list is not available:\n" * string(elem)
    return HTTP.Response(220, JSON3.write(msg))
end

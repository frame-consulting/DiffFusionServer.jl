
"""
    api_delete(
        request::HTTP.Request,
        repository::AbstractDict,
        options::Options,
        )

Delete an object from repository.

Request header must contain field 'alias'. The value of field
'alias' is the object alias of requested object in the server
repository.
"""
function api_delete(
    request::HTTP.Request,
    repository::AbstractDict,
    options::Options,
    )
    res = _check_for_header_field(request, "alias")
    if isa(res, HTTP.Message)
        return res
    end
    res = _check_for_alias_in_repository(res, repository)
    if isa(res, HTTP.Message)
        return res
    end
    alias = res
    obj_type = string(typeof(repository[alias]))
    delete!(repository, alias)
    msg = "Deleted object with alias " * alias * " and object type " * obj_type * "."
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(msg))
end

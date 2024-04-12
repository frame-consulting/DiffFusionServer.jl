
"""
    api_get_info(request::HTTP.Request)

Return an info string about the API as response.
"""
function api_get_info(request::HTTP.Request)
    return HTTP.Response(_NO_HTTP_ERROR, _INFO_STRING)
end


"""
    api_get_aliases(
        request::HTTP.Request,
        repository::AbstractDict,
        options::Options,
        )

Return all aliases from the repository in body of response.
"""
function api_get_aliases(
    request::HTTP.Request,
    repository::AbstractDict,
    options::Options,
    )
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(keys(repository)))
end

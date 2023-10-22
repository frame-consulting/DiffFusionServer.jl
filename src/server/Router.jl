
"""
    api_get_info(req::HTTP.Request)

Return an info string about the API as response.
"""
function api_get_info(req::HTTP.Request)
    return HTTP.Response(_NO_HTTP_ERROR, _INFO_STRING)
end


"""
Return all aliases from the repository in body of response.
"""
function api_get_aliases(req::HTTP.Request, d::AbstractDict)
    return HTTP.Response(_NO_HTTP_ERROR, JSON3.write(keys(d)))
end


function router(
    api_path = _DEFAULT_API_PATH,
    api_version = _DEFAULT_API_VERSION,
    )
    d = initial_repository()
    r = HTTP.Router()
    #
    _get_aliases(req::HTTP.Request) = api_get_aliases(req, d)
    #
    api_prefix = api_path * api_version
    #
    HTTP.register!(r, "GET", api_prefix * _INFO_END_POINT, api_get_info)
    HTTP.register!(r, "GET", api_prefix * _ALIASES_END_POINT, _get_aliases)
    #
    return (router=r, repository=d)
end
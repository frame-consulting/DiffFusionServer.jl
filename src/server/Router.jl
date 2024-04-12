
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
    router = HTTP.Router()
    repository = initial_repository()
    options = initial_options()
    # we need to link the repository to the handler functions
    _get_aliases(req::HTTP.Request) = api_get_aliases(req, repository, options)
    _get(req::HTTP.Request) = api_get(req, repository, options)
    _post(req::HTTP.Request) = api_post(req, repository, options)
    _delete(req::HTTP.Request) = api_delete(req, repository, options)
    _bulk_get(req::HTTP.Request) = api_bulk_get(req, repository, options)
    _bulk_post(req::HTTP.Request) = api_bulk_post(req, repository, options)
    #
    api_prefix = api_path * api_version
    #
    HTTP.register!(router, "GET", api_prefix * _INFO_END_POINT, api_get_info)
    HTTP.register!(router, "GET", api_prefix * _ALIASES_END_POINT, _get_aliases)
    HTTP.register!(router, "GET", api_prefix * _OPS_END_POINT, _get)
    HTTP.register!(router, "POST", api_prefix * _OPS_END_POINT, _post)
    HTTP.register!(router, "DELETE", api_prefix * _OPS_END_POINT, _delete)
    HTTP.register!(router, "GET", api_prefix * _BULK_OPS_END_POINT, _bulk_get)
    HTTP.register!(router, "POST", api_prefix * _BULK_OPS_END_POINT, _bulk_post)
    #
    return (
        router = router,
        repository = repository,
    )
end

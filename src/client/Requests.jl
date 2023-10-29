
function info(url::AbstractString = _DEFAULT_SERVER_URL)
    resp = HTTP.get(url * _INFO_END_POINT, status_exception=false)
    return (body=String(resp.body), status=resp.status)
end

function aliases(url::AbstractString = _DEFAULT_SERVER_URL)
    resp = HTTP.get(url * _ALIASES_END_POINT, status_exception=false)
    return (body=JSON3.read(resp.body), status=resp.status)
end

function get(
    alias::AbstractString,
    op::AbstractString = _BUILD_OP,
    url::AbstractString = _DEFAULT_SERVER_URL,
    )
    #
    headers = [ "alias" => alias, "op" => op, ]
    resp = HTTP.get(url * _OPS_END_POINT, headers, status_exception=false)
    return (body=JSON3.read(resp.body), status=resp.status)
end

function post(
    alias::AbstractString,
    obj::Any,
    op::AbstractString = _BUILD_OP,
    url::AbstractString = _DEFAULT_SERVER_URL,
    )
    #
    @assert op in _OPERATIONS
    if op == _BUILD_OP
        obj = DiffFusion.serialise(obj)
    end
    json3_string = JSON3.write(obj)
    headers = [ "alias" => alias, "op" => op, ]
    resp = HTTP.post(url * _OPS_END_POINT, headers, json3_string, status_exception=false)
    return (body=JSON3.read(resp.body), status=resp.status)
end

function delete(
    alias::AbstractString,
    url::AbstractString = _DEFAULT_SERVER_URL,
    )
    #
    headers = [ "alias" => alias, ]
    resp = HTTP.delete(url * _OPS_END_POINT, headers, status_exception=false)
    return (body=JSON3.read(resp.body), status=resp.status)    
end

function get_bulk(
    alias_list::AbstractVector,
    op::AbstractString = _BUILD_OP,
    url::AbstractString = _DEFAULT_SERVER_URL,
    )
    #
    headers = [ "op" => op, ]
    json3_string = JSON3.write(alias_list)
    resp = HTTP.get(url * _BULK_OPS_END_POINT, headers, json3_string, status_exception=false)
    return (body=JSON3.read(resp.body), status=resp.status)
end

function post_bulk(
    elem_list::AbstractVector,
    op::AbstractString = _BUILD_OP,
    url::AbstractString = _DEFAULT_SERVER_URL,
    )
    #
    headers = [ "op" => op, ]
    json3_string = JSON3.write(elem_list)
    resp = HTTP.post(url * _BULK_OPS_END_POINT, headers, json3_string, status_exception=false)
    return (body=JSON3.read(resp.body), status=resp.status)
end

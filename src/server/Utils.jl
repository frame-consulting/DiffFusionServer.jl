
"""
    _check_for_header_field(req::HTTP.Request, key::AbstractString)

Return valid alias from rquest header or a response that returns error message.
"""
function _check_for_header_field(req::HTTP.Request, key::AbstractString)
    if !HTTP.Messages.hasheader(req, key)
        return _error_key_not_found(key)
    end
    return HTTP.Messages.header(req, key)
end


"""
    _check_for_alias_in_repository(alias::AbstractString, d::AbstractDict)

Return valid alias from repository or a response that returns error message.
"""
function _check_for_alias_in_repository(alias::AbstractString, d::AbstractDict)
    if !haskey(d, alias)
        return _error_alias_not_found(alias)
    end
    return alias
end

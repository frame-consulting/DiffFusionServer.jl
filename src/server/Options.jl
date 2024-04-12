
"""
    mutable struct Options
        is_busy::Bool
    end

A container that holds flags and data which control the behaviour of the router.

The options object is created at inception of the router and passed to the
various handler functions.

`Options` element `is_busy` specifies that the server currently does not accept
POST requests. The flag may be set via the *is_busy* header field in a POST
request. The flag may be de-activated via the *is_busy* header field in
(subsequent) GET request.
"""
mutable struct Options
    is_busy::Bool
end


"""
    initial_options(
        is_busy::Bool = false,
        )

Create an `Options` object and initialise with default settings. 
"""
function initial_options(
    is_busy::Bool = false,
    )
    return Options(is_busy)
end

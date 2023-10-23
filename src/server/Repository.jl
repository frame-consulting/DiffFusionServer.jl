
"""
    initial_repository()

Create an object repository and initialise with some static objects.
"""
function initial_repository()
    d = Dict{String,Any}()
    #
    d["true"] = true
    d["false"] = false
    d["NoPathInterpolation"] = DiffFusion.NoPathInterpolation
    d["LinearPathInterpolation"] = DiffFusion.LinearPathInterpolation
    #
    d["SobolBrownianIncrements"] = DiffFusion.sobol_brownian_increments
    #
    return d
end

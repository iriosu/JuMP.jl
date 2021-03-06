export PSDCone
# Used in @constraint m X in PSDCone
struct PSDCone end

struct SDVariableConstraint{MT<:AbstractMatrix{JuMP.Variable}} <: AbstractConstraint
    Q::MT
end

# Used by the @variable macro. Currently cannot also be used through the @constraint macro because of the underscore
# It needs a larger discussion on whether we want to allow adding VectorOfVariable in cone using the @constraint macro.
function _constructconstraint!(Q::Matrix{JuMP.Variable}, ::PSDCone)
    #@assert issymmetric(Q) # TODO it could be nonsymmetric if used through the @constraint macro
    SDVariableConstraint(Q)
end

function moi_function_and_set(c::SDVariableConstraint)
    @assert issymmetric(c.Q)
    n = Base.LinAlg.checksquare(c.Q)
    return (MOI.VectorOfVariables([index(c.Q[i, j]) for j in 1:n for i in 1:j]), MOI.PositiveSemidefiniteConeTriangle(n))
end

function constructconstraint!(x::AbstractMatrix, ::PSDCone)
    n = Base.LinAlg.checksquare(x)
    # Support for non-symmetric matrices as done prior to JuMP v0.19
    # will be added once the appropriate cone has been added in MathOptInterface
    # as discussed in the following PR:
    # https://github.com/JuliaOpt/JuMP.jl/pull/1122#issuecomment-344980944
    @assert issymmetric(x)
    aff = [x[i, j] for j in 1:n for i in 1:j]
    s = MOI.PositiveSemidefiniteConeTriangle(n)
    return VectorAffExprConstraint(aff, s)
end

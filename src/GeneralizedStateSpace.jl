include("helpers.jl")
include("Blocks/Sources.jl")

import ControlSystems

# Alias to make extensions less verbose. Maybe I should import the functions?
CS = ControlSystems



# ---------------------------- Generalized state space--------------------------------------
# Generalized state space form:
#       ẋ = f(x, u, t)
#       y = h(x, u, t)
#
#   where
#       x: internal states variables
#       u: input state variables
#       y: output state variables
#       t: simulation time
#       f: state function
#       h: output function
# ------------------------------------------------------------------------------------------
abstract type SSFunction end

# State function (f from generalized state space form)
struct StateFunction{Initialized} <: SSFunction
    func::Function
    init_cond

    StateFunction(func, init_cond) = new{true}(func, init_cond)
    StateFunction(func) = new{false}(func, nothing)
end

# Output function (h from generalized state space form)
struct OutputFunction{Feedthrough} <: SSFunction
    func::Function

    function OutputFunction(func)
        narg_vect = nargin(func)
        nmethods = length(narg_vect)
        nargs = narg_vect[1]

        @assert(nmethods==1,
            "Output function must have only 1 method, instead it has $nmethods"
        )

        if nargs==2
            feedthrough = false
        elseif nargs==3
            feedthrough = true
        else
            error("Output function must have 2 or 3 arguments, instead it has $nargs")
        end

        return new{feedthrough}(func)
    end
end

# # Feedthrough output functions are of form:
# #   h(x, u, t)
# struct FeedthroughOutputFunction <: AbstractOutputFunction
#     func::Function
#     nu::Int
#     ny::Int
# end
#
# # Output functions (non-feedthrough) are of form:
# #   h(x, t)
# struct OutputFunction <: AbstractOutputFunction
#     func::Function
#     ny::Int
# end

(f::SSFunction)(args...; kwargs...) = f.func(args...; kwargs...)


# function CS.state_space_validation(f::Function, h::Function, Ts)
#     f_narg_vect, h_narg_vect = (f, h) .|> nargin
#
#     @assert(length(f_narg_vect)==length(h_narg_vect)==1,
#         "State and output functions must have only one method"
#     )
#     @assert(Ts ≥ 0 || Ts == -1,
#         "Ts must be either a positive number, 0 (continuous system), or -1 (unspecified)"
#     )
#
#     f_nargs, h_nargs = f_narg_vect[1], h_narg_vect[1]
#
#
#     if h_nargs==2
#         h_type = OutputFunction
#     elseif h_nargs==3
#         h_type = FeedthroughOutputFunction
#     else
#         error("Output function must have signature: h(x, u, t) or h(x, t)")
#     end
#
#     return f.nx, f_nargs, h_nargs, h_type
# end


struct NLStateSpace{Initialized, Feedthrough}
    f::StateFunction{Initialized}
    h::OutputFunction{Feedthrough}
    x
    y
    Ts
    in
    out
end
function NLStateSpace(f, h, Ts=-1, in=[], out=[])
    f = StateFunction(f)
    h = OutputFunction(h)
    return NLStateSpace(f, h, Ts, in, out)
end

# abstract type AbstractNLStateSpace end
#
# struct FeedthroughNLStateSpace <: AbstractNLStateSpace
#     f::StateFunction
#     h::FeedthroughOutputFunction
#     Ts #::Float64
#     in
#     out
# end
#
# struct NLStateSpace <: AbstractNLStateSpace
#     f::StateFunction
#     h::OutputFunction
#     Ts #::Float64
#     in
#     out
#     NLStateSpace(f, h, Ts=-1) = new(f, h, Ts, CS.state_space_validation(f, h, Ts)...)
# end
#
#
# function (sys::AbstractNLStateSpace)(u)
#
# end
#
# # Extend ss method to create NLStateSpace type when functions are passed in
# function CS.ss(f::Function, h::Function, args..., kwargs...)
#     return
# end
# CS.ss(f::Function, h::OutputFunction, args...; kwargs...) =
#     NLStateSpace(f, h, args...; kwargs...)
# CS.ss(f::Function, h::FeedthroughOutputFunction, args...; kwargs...) =
#     FeedthroughNLStateSpace(f, h, args...; kwargs...)
#
# GeneralizedStateSpace = Union{CS.StateSpace, NLStateSpace}




initial_conditions(f::StateFunction) = f.init_cond
initial_conditions(sys::NLStateSpace) = sys.f.init_cond

CS.ninputs(sys::NLStateSpace) = sys.nu
CS.noutputs(sys::NLStateSpace) = sys.ny

# Indexing Functions
Base.ndims(::NLStateSpace) = 2
Base.size(sys::NLStateSpace) = (noutputs(sys), ninputs(sys))
Base.size(sys::NLStateSpace, d::Integer) = d <= 2 ? size(sys)[d] : 1
Base.eltype(::Type{S}) where {S<:NLStateSpace} = S

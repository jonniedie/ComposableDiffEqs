using ControlSystems

# Alias to make extensions less verbose. Maybe I should import the functions?
CS = ControlSystems

# ------------------------------------ Sources ---------------------------------------------
abstract type DiscreteSource end

struct PulseTrain <: DiscreteSource
    amplitude
    period
    duty
end

struct Step <: DiscreteSource
    amplitude
    steptime
end

struct ContinuousSource
    func
end

Source = Union{DiscreteSource, ContinuousSource}



# ----------------------------- State-Space Functions---------------------------------------
# ODEFunction wrappers that keep track of number of input, internal, and output variables.
abstract type SSFunction <: Function end

struct StateFunction <: SSFunction
    func::Function
    nu::Int
    init_cond
    StateFunction(func, nu, init_cond=nothing) = new(func, nu, init_cond)
end

struct OutputFunction <: SSFunction
    func::Function
    nu::Int
    ny::Int
end

(f::SSFunction)(args...; kwargs...) = f.func(args...; kwargs...)


function CS.state_space_validation(f::StateFunction, h::OutputFunction, Ts)
    @assert(f.nu == h.nu,
        "State and output functions must have same number of control variables"
    )
    @assert(Ts ≥ 0 || Ts == -1,
        "Ts must be either a positive number, 0 (continuous system), or -1 (unspecified)"
    )
    return f.nu, h.ny
end


struct NLStateSpace
    f::Function
    h::Function
    Ts #::Float64
    nu::Int
    ny::Int
    NLStateSpace(f, h, Ts=-1) = new(f, h, Ts, CS.state_space_validation(f, h, Ts)...)
end
function (sys::NLStateSpace)(u)

end

# Extend ss method to create NLStateSpace type when functions are passed in
CS.ss(f::Function, h::Function, args...; kwargs...) = NLStateSpace(f, h, args...; kwargs...)

GeneralizedStateSpace = Union{CS.StateSpace, NLStateSpace}


# ------------------------------- Simulation Model -----------------------------------------
struct SimModel
    source

end





initial_conditions(f::StateFunction) = f.init_cond
initial_conditions(sys::NLStateSpace) = sys.f.init_cond

CS.ninputs(sys::NLStateSpace) = sys.nu
CS.noutputs(sys::NLStateSpace) = sys.ny

# function Base.:+(sys1::NLStateSpace, sys2::NLStateSpace)
#     @assert(size(sys1) == size(sys2), "Systems have different shapes")
#     @assert(sys1.Ts == sys2.Ts, "Sampling time mismatch")
#
#     # f(x) = sys1.f(x[1:nstates(sys1)])
# end

# Note reverse order of sys1 and sys2 because of right-to-left operation
function Base.:*(sys2::NLStateSpace, sys1::NLStateSpace)
    # Check that input/output dimensions and sampling times are compatable
    @assert(CS.ninputs(sys1) == CS.noutputs(sys2),
        "sys1 must have same number of inputs as sys2 has outputs"
    )
    @assert(sys1.Ts == sys2.Ts, "Sampling time mismatch")

    # Input/output dimensions
    nu = sys1.nu
    ny = sys2.ny

    # Initial conditions
    init = initial_conditions.([sys1, sys2])

    # New state function
    function f!(dx, x, u, t)
        dx1, dx2, x1, x2 = @views dx[1], dx[2], x[1], x[2]
        y = sys1.h(x1, u, t)
        sys1.f(dx1, x1, u, t)
        sys2.f(dx2, x2, y, t)
        return nothing
    end

    # New output function
    h(x, u, t) = sys2.h(x[2], sys1.h(x[1], u, t), t)

    return NLStateSpace(StateFunction(f!, nu, init), OutputFunction(h, nu, ny), sys1.Ts)
end

# Indexing Functions
Base.ndims(::NLStateSpace) = 2
Base.size(sys::NLStateSpace) = (noutputs(sys), ninputs(sys))
Base.size(sys::NLStateSpace, d::Integer) = d <= 2 ? size(sys)[d] : 1
Base.eltype(::Type{S}) where {S<:NLStateSpace} = S

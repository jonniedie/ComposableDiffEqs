using ModelingToolkit
MTK = ModelingToolkit

# function MTK.to_diffeq(eq::Equation)
#     if isintermediate(eq)
#
#     end
#     (x, t, n) = flatten_differential(eq.lhs)
#     (isa(t, Operation) && isa(t.op, Variable) && isempty(t.args)) ||
#         throw(ArgumentError("invalid independent variable $t"))
#     (isa(x, Operation) && isa(x.op, Variable) && length(x.args) == 1 && isequal(first(x.args), t)) ||
#         throw(ArgumentError("invalid dependent variable $x"))
#     return t.op, DiffEq(x.op, n, eq.rhs)
# end
#
# function DAESystem(eqs)
#     reformatted = to_dae.(eqs)
# end
isnamedin(varname, varlist) = reduce((x1,x2)-> x1 || x2.name==varname, varlist; init=false)




abstract type Reference <: Expression end

struct VarRef <: Reference
    sys::MTK.AbstractSystem
    ref
end

struct ParamRef <: Reference
    sys::MTK.AbstractSystem
    ref
end

struct Component
    name::Symbol
    subcomponents::Array{Component,1}
    connections::Array{Equation,1}
    sys::Union{ODESystem, Nothing}
    function Component(name, eqs::Array{Equation,1})
        sc, con, sys = parse(eqs)
        return new(Symbol(name), sc, con, sys)
    end
end

macro component(sys::ODESystem)

end


function Base.parse(eqs::Array{Equation,1})
    sc = get_systems(eqs)

end


struct SuperSystem <: MTK.AbstractSystem
    systems::Array{MTK.AbstractSystem,1}
    con_eqs::Array{Equation,1}
    eqs::Array{MTK.DiffEq,1}
    iv::Variable
    dvs::Array{Variable,1}
    ps::Array{Variable,1}
    jac::Base.RefValue{Array{Expression,2}}
    Wfact::Base.RefValue{Array{Expression,2}}
    Wfact_t::Base.RefValue{Array{Expression,2}}
end
function SuperSystem(eqs::Array{Equation,1})
end

get_systems(x) = []
get_systems(ode::ODESystem) = [ode]
get_systems(ref::Reference) = [ref.sys]
get_systems(op::Operation) = get_systems(op.args)
get_systems(arr::Array) = vcat(get_systems.(arr)...) |> unique
function get_systems(eq::Equation)
    @assert isa(eq.lhs, VarRef) "lhs must be a VarRef. DAEs aren't supported yet."
    return get_systems([eq.lhs, eq.rhs]) |> Array{MTK.AbstractSystem}
end



Base.convert(::Type{Expr}, ref::Reference) =
    MTK.build_expr(:call, Any[Symbol])


function Base.getindex(sys::ODESystem, key)
    if isnamedin(key, sys.ps)
        return ParamRef(sys, key)
    elseif isnamedin(key, sys.dvs)
        return VarRef(sys, key)
    else
        throw(ArgumentError("invalid index: $key"))
    end
end

function Base.setindex!(sys::ODESystem, val::Reference, ref)
end

function Base.collect(sys::SuperSystem)

end

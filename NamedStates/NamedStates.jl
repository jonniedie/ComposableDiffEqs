using DifferentialEquations
using CoolDicts


struct NamedViewVector{T} <: AbstractVector{T}
    _namedtuple
    _vector::AbstractVector{T}
end

struct InternalVector{T} <: AbstractVector{T}
    _parent
    _vector::AbstractVector{T}
end
InternalVector(parent, ur::UnitRange) = InternalVector{eltype(ur)}(parent, collect(ur))


function NamedViewVector(nt::NamedTuple)
    _namedtuple = []
    _vector = []
    idx = 1
    for (key, val) in zip(keys(nt), values(nt))
        if val isa Number
            push!(_vector, val)
            push!(_namedtuple, key => idx)
            idx += 1
        elseif val isa AbstractVector
            push!(_vector, val...)
            push!(_namedtuple, key => InternalVector(_vector, idx .+ (0:length(val)-1)))
        # elseif val isa NamedTuple || val isa AbstractDict
        #     val = NamedViewVector(val)
        #     _nt = CoolDict()
        #     for (nvvkey, nvvval) in zip(keys(val), values(val))
        #         len = length(nvvval)
        #         push!(_vector, nvvval...)
        #         _nt[nvvkey] = @view _vector[(end-len+1):end]
        #     end
        #     _namedtuple[key] = NamedTuple(_nt)
        else
            error("$val must be a subtype of of Number or AbstractVector")
        end

    end
    _nt = (; _namedtuple...)
    return NamedViewVector{eltype([_vector...])}(_nt, _vector)
end

ViewableVector = Union{NamedViewVector, InternalVector}

namedtuple(nvv::NamedViewVector) = getfield(nvv, :_namedtuple)

vector(nvv::ViewableVector) = getfield(nvv, :_vector)

Base.size(nvv::ViewableVector) = size(vector(nvv))

Base.length(nvv::ViewableVector) = length(vector(nvv))

Base.iterate(nvv::ViewableVector, args...; kwargs...) =
    iterate(vector(nvv), args...; kwargs...)

Base.getindex(nvv::ViewableVector, idx) = vector(nvv)[idx]
Base.getindex(nvv::NamedViewVector, key::Symbol) = nvv[namedtuple(nvv)[key]]

Base.setindex!(iv::InternalVector, value, idx) = setindex!(iv._parent, value, iv._vector[idx])
Base.setindex!(nvv::NamedViewVector, value, idx) = (vector(nvv)[idx] = value)
Base.setindex!(nvv::NamedViewVector, value, key::Symbol) = (nvv[namedtuple(nvv)[key]] = value)

function Base.getproperty(nvv::NamedViewVector, key::Symbol)
    if key in [:_namedtuple, :_vector]
        error("Hey, the $key field is sorta private. If you want to access it, you can use getfield(myobj, :$key) though. Sorry.")
    else
        return nvv[key]
    end
end
Base.setproperty!(nvv::NamedViewVector, key::Symbol, value) = setindex!(nvv, value, key)

Base.keys(nvv::NamedViewVector) = keys(namedtuple(nvv))

Base.values(nvv::NamedViewVector) = values(namedtuple(nvv))

Base.view(nvv::NamedViewVector, inds...) = view(vector(nvv), namedtuple(nvv)[inds...])

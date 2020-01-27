include("MutableNamedTuples.jl")

import RecursiveArrayTools:
    recursive_unitless_eltype,
    recursive_bottom_eltype,
    recursive_unitless_bottom_eltype,
    recursivecopy

# Convenience closure for creating NamedTuple constructor
Struct(keys...) = (args...) -> NamedTuple{(keys)}(args)

struct NamedViewVector{T} <: AbstractVector{T}
    data::MutableNamedTuple
    vector::AbstractVector
end
function NamedViewVector(mnt::MutableNamedTuple)
    vector = []
    for (key, val) in zip(keys(mnt), values(mnt))
        if val[1] isa Number
            push!(vector, view(val, 1))
        elseif val[1] isa AbstractVector
            for i in eachindex(val[1])
                push!(vector, view(val[1], i))
            end
        elseif val[1] isa MutableNamedTuple
            nvv = NamedViewVector(val[1])
            for i in eachindex(nvv)
                push!(vector, view(nvv, i))
            end
        end
    end
    return NamedViewVector{viewvect_bottom_type(vector)}(mnt, vector)
end
NamedViewVector(nt::NamedTuple) = NamedViewVector(MutableNamedTuple(nt))

Base.length(nvv::NamedViewVector) = length(getfield(nvv, :vector))

Base.size(nvv::NamedViewVector) = size(getfield(nvv, :vector))

Base.getindex(nvv::NamedViewVector, i::Int) = getfield(nvv, :vector)[i]
Base.getindex(nvv::NamedViewVector, I::Vararg{Int,N}) where {N} = getfield(nvv, :vector)[I...]
Base.getindex(nvv::NamedViewVector, ::Colon) = getfield(nvv, :vector)[:]
Base.getindex(nvv::NamedViewVector, kr::AbstractRange) = getfield(nvv, :vector)[kr]

# Base.getindex(nvv::NamedViewVector, idx...) = getfield(nvv, :vector)[idx...]
Base.getindex(nvv::NamedViewVector, key::Symbol) = getfield(nvv, :data)[key]

Base.setindex!(nvv::NamedViewVector, v, i::Int) = (getfield(nvv, :vector)[i][1] = v)
# Base.setindex!(nvv::NamedViewVector, v, I::Vararg{Int,N}) where {N} = (getfield(nvv, :vector)[I...] .= v)
function Base.setindex!(nvv::NamedViewVector, v, ::Colon)
    for i in eachindex(nvv)
        getfield(nvv, :vector)[i][1] = v
    end
    return nothing
end
function Base.setindex!(nvv::NamedViewVector, v, kr::AbstractRange)
    for i in kr
        getfield(nvv, :vector)[kr][1] = v
    end
    return nothing
end
Base.setindex!(nvv::NamedViewVector, value, key::Symbol) = (getfield(nvv, :vector)[key][1] = value)

Base.copyto!(nvv::NamedViewVector, src::AbstractArray) = (nvv[1:length(src)] = src)
Base.copyto!(nvv::NamedViewVector, src::Base.Broadcast.Broadcasted) = (nvv[1:length(src)] = src)
function Base.copyto!(nvv::NamedViewVector, doff, src, soff, N)
    rng = 0:N-1
    nvv[doff .+ rng] = src[soff .+ rng]
    return nvv
end

Base.getproperty(nvv::NamedViewVector, key::Symbol) = getfield(nvv, :data)[key]

Base.setproperty!(nvv::NamedViewVector, key::Symbol, val) = (getfield(nvv, :data)[key] = val)

Base.propertynames(nvv::NamedViewVector) = propertynames(getfield(nvv, :data))

Base.similar(nvv::NamedViewVector) = NamedViewVector(namedtuple(getfield(nvv, :data)))
# TODO: Need to figure out how to make this work
# Base.similar(nvv::NamedViewVector,::Type{T}) where T = NamedViewVector(namedtuple(getfield(nvv, :data)))

# Yikes. FIXME.
viewvect_bottom_type(vector) = map(x->x[1][1], vector) |> eltype
recursive_unitless_bottom_eltype(nvv::NamedViewVector) = eltype(nvv)
recursive_bottom_eltype(nvv::NamedViewVector) = recursive_unitless_bottom_eltype(nvv)
recursive_unitless_eltype(nvv::NamedViewVector) = recursive_unitless_bottom_eltype(nvv)
recursivecopy(nvv::NamedViewVector) = deepcopy(nvv)

Base.abs2(sa::SubArray) = abs2.(sa)
Base.:/(sa1::SubArray, sa2::SubArray) = sa1 ./ sa2
Base.isnan(sa::SubArray) = isnan.(sa)

vector(nvv::NamedViewVector) = getfield(nvv, :vector)

# Base.:+(nvv1::NamedViewVector, nvv2::NamedViewVector) = vector(nvv1) + vector(nvv2)
# Base.:*(x::Number, nvv::NamedViewVector) = x * vector(nvv)

# TODO: Write documentation and comments
struct MutableNamedTuple{K,T}
    data::NamedTuple{K,T}
    function MutableNamedTuple(nt::NamedTuple)
        data = []
        for (key, val) in zip(keys(nt), values(nt))
            if val isa NamedTuple
                val = MutableNamedTuple(val)
            end
            push!(data, key => [val])
        end
        nt = (; data...)
        K,T = typeof(nt).parameters
        return new{K,T}(nt)
    end
end
MutableNamedTuple(; kwargs...) = MutableNamedTuple((;kwargs...))

Base.getproperty(mnt::MutableNamedTuple, key::Symbol) = getfield(mnt, :data)[key][1]
Base.propertynames(mnt::MutableNamedTuple) = propertynames(getfield(mnt, :data))
Base.setproperty!(mnt::MutableNamedTuple, key::Symbol, val) =
    (getfield(mnt, :data)[key][1] = val)

Base.getindex(mnt::MutableNamedTuple, key::Symbol) = getproperty(mnt, key)
Base.setindex!(mnt::MutableNamedTuple, val, key::Symbol) = setproperty!(mnt, key, val)

function namedtuple(mnt::MutableNamedTuple)
    data = []
    for (key, val) in zip(keys(mnt), values(mnt))
        val = val[1]
        if val isa MutableNamedTuple
            val = namedtuple(val)
        end
        push!(data, key => val)
    end
    return (; data...)
end

function Base.show(io::IO, mnt::MutableNamedTuple)
    show(io, namedtuple(mnt))
    return nothing
end
function Base.show(io::IO, ::MIME"text/plain", mnt::MutableNamedTuple)
    print(io, "MutableNamedTuple")
    show(io, namedtuple(mnt))
    return nothing
end

Base.keys(mnt::MutableNamedTuple) = keys(getfield(mnt, :data))
Base.values(mnt::MutableNamedTuple) = values(getfield(mnt, :data))

Base.length(mnt::MutableNamedTuple) = length(getfield(mnt, :data))
Base.size(mnt::MutableNamedTuple) = size(getfield(mnt, :data))

abstract type Port end

mutable struct Input
    sys::NLStateSpace
    id
    subscription
    Input(sys; id=1, subscription=nothing) = new(sys, id, subscription)
end

mutable struct Output
    sys::NLStateSpace
    id
    subscribers::Array{Input}
    Output(sys; id=1, subscribers=[]) = new(sys, id, subscribers)
end


function connect(in::Input, out::Output)
    out.sys.f = combine(out.sys.f, in.sys.f, in.sys.h)
    out.sys.h = combine(out.sys.h, in.sys.h)
end

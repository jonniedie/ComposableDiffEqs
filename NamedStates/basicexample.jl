include("NamedViewVector.jl")

using DifferentialEquations

function de1(dx, x, p, t)
    dx = x
    return nothing
end

function de2(dx, x, p, t)
    dx.x1 = x.x2
    dx.x2 = -p*x.x1
    return nothing
end

function de(dx, x, p, t)
    de1(dx.y, x.y, x.x.x1, t)
    de2(dx.x, x.x, x.y, t)
    return nothing
end

p = 0.0

x0 = NamedViewVector{Float64}((x=(x1=1.0, x2=2.0), y=3.0))

prob = ODEProblem(de, x0, (0.0, 10.0), p)
sol = solve(prob, Tsit5())

"""
Example taken from:
https://github.com/JuliaDiffEq/ModelingToolkit.jl/issues/36#issuecomment-536221300
"""

include("NamedViewVector.jl")

using DifferentialEquations
using Plots
using Interact

theme(:juno)
settheme!(:nativehtml)


function lorenz!(du, u, (p, f), t)
    x, y, z = u.x, u.y, u.z
    σ, ρ, β = p.σ, p.ρ, p.β

    du.x = σ*(y - x)
    du.y = x*(ρ - z) - y + f
    du.z = x*y - β*z
    return nothing
end

function lotka!(du, u, (p, f), t)
    x, y = u.x, u.y
    α, β, γ, δ = p.α, p.β, p.γ, p.δ

    du.x = α*x - β*x*y + f
    du.y = -γ*y + δ*x*y
    return nothing
end

function composed!(du, u, p, t)
    lorenz!(du.lorenz, u.lorenz, (p, u.lotka.x), t)
    lotka!(du.lotka, u.lotka, (p, u.lorenz.x), t)
    return nothing
end

p = (α=1.0, β=2.5, γ=3.1, δ=0.5, ρ=1.0, σ=0.1)

prange = 0 : 0.01 : 10

tspan = (0.0, 20.0)
lorenz_ic = (x=0.0, y=0.0, z=0.0)
lotka_ic = (x=1.0, y=1.0)

u₀ = NamedViewVector{Float64}((lorenz=lorenz_ic, lotka=lotka_ic))

prob = ODEProblem(composed!, u₀, tspan, p)
sol = solve(prob, Tsit5())

plot(sol)

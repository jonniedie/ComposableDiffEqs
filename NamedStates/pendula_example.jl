include("NamedViewVector.jl")

using DifferentialEquations
using Plots

theme(:juno)
plotly()


# -- Constants -----------------------------------------------------------------------------
# Gravitational constant
const G0 = 9.80665


# -- Component equations -------------------------------------------------------------------
function pendulum!(dθ, θ, p, t)
    dθ.pos = θ.vel
    dθ.vel = p.M - G0/p.L*sin(θ.pos)
    return nothing
end

function cart!(dx, x, F, t)
    dx.pos = x.vel
    dx.vel = F
    return nothing
end

function composed!(du, u, p, t)

    pendulum!(du.θ, u.θ, , t)
    cart!(du.x, u.x, F, t)
end

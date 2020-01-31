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
    m, L, ΣM = p.mass, p.L, p.ΣM

    dθ.pos = θ.vel
    dθ.vel = (ΣM - m*G0*sin(θ.pos)) / (m*L)
    return nothing
end

function cart!(dx, x, p, t)
    m, ΣF = p.mass, p.ΣF

    dx.pos = x.vel
    dx.vel = ΣF/m
    return nothing
end

function composed!(du, u, p, t)
    m, L = p.pend.mass, p.pend.L
    M = p.cart.mass

    pendulum!(du.θ, u.θ, (mass=m, L=L, ΣM=), t)
    cart!(du.x, u.x, (mass=m+M, ΣF=), t)
end

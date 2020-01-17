include("Components.jl")

## Example from https://github.com/JuliaDiffEq/ModelingToolkit.jl/issues/36

# System 1
@parameters t σ ρ β f(t)
@variables x(t) y(t) z(t)
@derivatives D'~t
eqs = [
    D(x) ~ σ*(y-x),
    D(y) ~ x*(ρ-z)-y + f,
    D(z) ~ x*y - β*z
]
lorenz = ODESystem(eqs)


# System 2
@parameters t α β γ δ f(t)
@variables x(t) y(t)
@derivatives D'~t
eqs = [
    D(x) ~ α*x - β*x*y + f,
    D(y) ~ -γ*y + δ*x*y
]
lotka = ODESystem(eqs)
lotka1 = Component(:lotka, eqs)
lotka2 = Component(:lotka, lotka)
lotka3 = @component lotka

# Composed system
@parameters t α q(t)
@variables x(t)
eqs = [
    lorenz[:f] ~ lotka[:x] + q,
    lotka[:f] ~ lorenz[:x] - 3*lorenz[:y],
    lotka[:β] ~ lorenz[:β],
    lotka[:α] ~ α,
    D(x) ~ α*x  + lorenz[:x]*lotka[:x] - q
]
sys = Component(eqs)
collect(sys)


#= Should be
[
D(lorenz_x) ~ lorenz_σ*(lorenz_y-lorenz_x),
D(lorenz_y) ~ lorenz_x*(lorenz_ρ-lorenz_z)-lorenz_y + lotka_y,
D(lorenz_z) ~ lorenz_x*lorenz_y - lorenz_β*lorenz_z,
D(lotka_x)  ~ lotka_α*lotka_x - lotka_β*lotka_x*lotka_y + lorenz_x,
D(lotka_y)  ~ -lotka_γ*lotka_y + lotka_δ*lotka_x*lotka_y
]
=#

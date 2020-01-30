include("NamedViewVector.jl")

using DifferentialEquations
using LinearAlgebra: normalize, norm
using Plots

theme(:juno)
plotly()

# -- Constants -----------------------------------------------------------------------------
# Gravitational constant
const G0 = 9.80665


# -- Component equations -------------------------------------------------------------------
# Equations of motion
function EOM!(dx, x, p, t)
    dx.pos .= x.vel
    dx.vel .= p.F / p.mass
    return nothing
end

# Propellent mass equation
propellent(x, p, t) = -p.F / p.ISP / G0

# Velocity-aligned thrust (these aren't differential equations, we just need dx for
#   acceleration limiting)
thrust_on(vel, p) = p.F * normalize(vel)
thrust_off(vel, p) = zero(vel)
function thrust_vel_limited(vel, p)
    vel_mag = norm(vel)
    err = p.vel_setpoint - vel_mag
    F = p.kₚ * err
    return clamp(F, 0, p.max_F) / vel_mag * vel
end



# -- Full combined state equations ---------------------------------------------------------
function rocket!(dx, x, p, t)
    # Get force vector
    F = p.thrust(x.body.vel, p)
    F_mag = norm(F)
    F[end] -= G0 # Apply gravity

    # Run equations!
    EOM!(dx.body, x.body, (F=F, mass=p.dry_mass+x.prop_mass), t)
    dx.prop_mass = propellent(x.prop_mass, (ISP=p.ISP, F=F_mag), t)
    return nothing
end


# -- Event handling ------------------------------------------------------------------------
# Hitting the ground stops the simulation
ground_cond(x, t, integrator) = x.body.pos[end]
ground_affect!(integrator) = terminate!(integrator)
ground_cb = ContinuousCallback(ground_cond, nothing, ground_affect!)

# Running out of propellent stops thrust
prop_cond(x, t, integrator) = x.prop_mass
prop_affect!(integrator) = (integrator.p.thrust = thrust_off)
prop_cb = ContinuousCallback(prop_cond, nothing, prop_affect!)

# Combine callbacks
cb = CallbackSet(ground_cb, prop_cb)



# -- Parameters ----------------------------------------------------------------------------
# Specific impulse and vehicle dry mass
ISP = 150.0
dry_mass = 2.0

# Open-loop thrust parameters
thrust_function = thrust_vel_limited
max_F = 100.0
vel_setpoint = 1000.0
kₚ = 1.0

# Parameters
p = (
    ISP = ISP,
    max_F = max_F,
    dry_mass = dry_mass,
    thrust = thrust_function,
    vel_setpoint = vel_setpoint,
    kₚ = kₚ
    )


# -- Initial conditions --------------------------------------------------------------------
# Vehicle body initial conditions
pos₀ = [0.0, 0.0, 0.0]
vel₀ = [0.01, 0.02, 1.0] # Cannot be all zero because F wouldn't know where to point
body₀ = (
    pos = pos₀,
    vel = vel₀,
    )

# Mass initial conditions
prop_mass₀ = 7.0

# Full state initial conditions
vehicle₀ = (
    body = body₀,
    prop_mass = prop_mass₀,
    )


# -- Simulation setup ----------------------------------------------------------------------
# Simulation time span
tspan = (0.0, 10000.0)


# -- Run Simulation ------------------------------------------------------------------------
prob = ODEProblem(rocket!, NamedViewVector{Float64}(vehicle₀), tspan, MutableNamedTuple(p))
sol = solve(prob, Tsit5(), callback=cb)


# -- Plot solution -------------------------------------------------------------------------
vel_mag(u) = norm(u.body.vel)
ndof = length(pos₀)
t = range(sol.t[1], sol.t[end], length=1000)

p_pos = plot(sol, vars=1:ndof, legend=:best)
p_vel = plot(sol, vars=ndof+1:2ndof, legend=:best)
plot!(p_vel, sol(t).t, vel_mag.(sol(t).u), legend=:best, lw=2)
p_mass = plot(sol, vars=2ndof+1, legend=:best)

plot(p_pos, p_vel, p_mass, layout=(3,1))

plot(sol, vars=((1:ndof)...,), lw=2)

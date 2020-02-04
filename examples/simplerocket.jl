include("NamedViewVector.jl")

using DifferentialEquations
using LinearAlgebra: normalize, norm
using Plots

plotly()

# -- Constants -----------------------------------------------------------------------------
# Gravitational constant
const G0 = 9.80665


# -- Component equations -------------------------------------------------------------------
# Equations of motion
function EOM!(dx, x, p, t)
    @. dx.pos = x.vel
    @. dx.vel = p.F / p.mass
    return nothing
end

# Propellent mass equation
propellent(x, p, t) = -p.F / p.ISP / G0

# Velocity-aligned thrust
thrust_full(vel, ctrl) = ctrl.thrust_lim * normalize(vel)
thrust_off(vel, ctrl) = zero(vel)
function thrust_vel_limited(vel, ctrl)
    vel_mag = norm(vel)
    F = ctrl.k_p * (ctrl.vel_setpoint - vel_mag)
    return clamp(F, 0, ctrl.thrust_lim) / vel_mag * vel
end



# -- Full combined state equations ---------------------------------------------------------
function rocket!(dx, x, p, t)
    # Get force vector
    F = p.thrust(x.body.vel, p)
    F_mag = norm(F)
    F[end] -= G0 # Apply gravity

    # Run equations of motion!
    p_EOM = (F = F, mass = p.vehicle.dry_mass + x.prop_mass)
    EOM!(dx.body,x.body, p_EOM, t)

    # Run propellent equation
    p_prop = (ISP = p.vehicle.ISP, F = F_mag),
    dx.prop_mass = propellent(x.prop_mass, p_prop, t)

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
# Vehicle properties
p_vehicle = (
    dry_mass = 2.0,
    ISP = 150.0,
)

# Throttle control parameters
p_control = (
    thrust = thrust_vel_limited,
    thrust_lim = 100.0,
    vel_setpoint = 1000.0,
    k_p = 1.0,
)

# Parameters
p = (
    vehicle = p_vehicle,
    control = p_control,
)


# -- Initial conditions --------------------------------------------------------------------
# Vehicle body initial conditions
body₀ = (
    pos = [0.0, 0.0, 0.0],
    vel = [0.01, 0.02, 1.0],
)

# Full state initial conditions
vehicle₀ = (
    body = body₀,
    prop_mass = 7.0,
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

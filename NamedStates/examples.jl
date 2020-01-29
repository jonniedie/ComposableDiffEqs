include("NamedViewVector.jl")

using DifferentialEquations
using LinearAlgebra: normalize, norm


# -- Point mass equations of motion --------------------------------------------------------
# Equations of motion
function EOM!(dx, x, p, t)
    dx.pos .= x.vel
    dx.vel .= p.F / p.m
    return nothing
end


# -- Mass model --------------------------------------------------------------------
# Gravitational constant
G0 = 9.80665

# Mass equation
function mass!(dx, x, p, t)
    dx.mass = -norm(p.F) / p.ISP / G0
    return nothing
end
function mass(x, p, t)
    return -norm(p.F) / p.ISP / G0
end


# -- Full combined state equations ---------------------------------------------------------
function rocket!(dx, x, p, t)
    # F = p.F(t, x.body.vel)
    F = p.F
    EOM!(dx.body, x.body, (F=F, m=x.mass), t)
    mass!(dx, x, (ISP=p.ISP, F=F), t)
    # dx.mass = mass(x, (ISP=p.ISP, F=F), t)
    return nothing
end


# -- Open-loop thrust profile --------------------------------------------------------------
function thrust(tspan, max_thrust, t, vel)
    tdiff = tspan[2] - tspan[1]
    if tspan[1] < t < tspan[2]
        return max_thrust * (abs(sin(π * t / tdiff)))^(1/16) * normalize(vel)
    else
        return 0.0
    end
end
thrust(tspan, max_thrust) = (t, vel) -> thrust(tspan, max_thrust, t, vel)


# -- Simulation inputs ---------------------------------------------------------------------
# Specific impulse and vehicle dry mass
ISP = 150.0
dry_mass = 2.0

# Open-loop thrust parameters
max_F = 100.0
duration = 5.0

# Vehicle body initial conditions
pos₀ = [0.0, 0.0, 0.0]
vel₀ = [1.0, 0.0, 0.0] # Cannot be all zero because F wouldn't know where to point
body₀ = (pos = pos₀, vel = vel₀,)

# Mass initial conditions
prop_mass₀ = 5.0

# Full state initial conditions
vehicle₀ = (body = body₀, mass = dry_mass + prop_mass₀)


# -- Simulation setup ----------------------------------------------------------------------
# Simulation time span
tspan = (0.0, 10.0)

# Parameters
# p = (ISP = ISP, F = thrust((0.0, duration), max_F))
p = (ISP = ISP, F = [100.0, 0.0, 0.0])


# -- Run Simulation ------------------------------------------------------------------------
prob = ODEProblem(rocket!, NamedViewVector{Float64}(vehicle₀), tspan, p)
sol = solve(prob, Tsit5())

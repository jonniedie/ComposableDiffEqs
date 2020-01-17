include("../src/GeneralizedStateSpace.jl")

using DifferentialEquations
using Plots: plot, plot!, theme
using Interact: @manipulate, settheme!

theme(:juno)
settheme!(:nativehtml)

# ż = -2z + u
# ẍ = -x + z
# y = 3x + z
#
# ż = -2z + u
# ẋ = v
# v̇ = -x + z
# y = z + 3x
#
# dx[1] = -2*x[1]               + u
# dx[2] =                  x[3]
# dx[3] =    x[1] - x[2]

function f1!(dx, x, u, t)
    dx[1] = -2*x[1] + u
    return nothing
end
function f2!(dx, x, u, t)
    dx[1] = x[2]
    dx[2] = u[1] - x[1]
    return nothing
end
function f!(dx, x, u, t)
    dx[1] = -2*x[1] + u
    dx[2] = x[3]
    dx[3] = x[1] - x[2]
    return nothing
end

h1(x, t) = x[1]
h2(x, u, t) = u[1] + 3*x[1]
h(x, t) = x[1] + 3*x[2]

sys_base = NLStateSpace(StateFunction(f!, 1), OutputFunction(h, 1))
sys1 = NLStateSpace(StateFunction(f1!, 1), OutputFunction(h1, 1, 1))
sys2 = NLStateSpace(StateFunction(f2!, 1), OutputFunction(h2, 1, 1))
sys_comp = sys2 * sys1

# Pulse width modulation
pwm(t, period, duty) = mod(t, period) ≤ duty*period ? 1 : 0
pwm(period, duty) = t -> pwm(t, period, duty)

# Trigger times for pwm to be passed into the solver tstops keyword argument
vzip(vect1, vect2) = vcat([vcat(v1, v2) for (v1, v2) in zip(vect1, vect2)]...)
function pwm_triggers(stoptime, period, duty)
    rise = period:period:stoptime
    fall = rise .+ duty*period
    return vzip(rise, fall)
end

x₀ = [0., 0., 0.]
tspan = (0., 20.)

# Pulse width modulation
# period = 0.1
# duty = 1/3
# u(t) = pwm(t, period, duty)
u = 1

@manipulate for duty = 0.01:0.01:1-0.01, period=0.01:0.01:3
    u_const = duty
    tstops = pwm_triggers(tspan[2], period, duty)

    affect!(integrator) = (integrator.p = 1 - integrator.p)
    time_choice(integrator) = integrator.t + period*(integrator.p==1 ? duty : (1-duty))
    cb = IterativeCallback(time_choice, affect!)

    prob_base = ODEProblem(ODEFunction{true}(sys_base.f), x₀, tspan, u_const)
    prob_comp = ODEProblem(ODEFunction{true}(sys_base.f), x₀, tspan, u)

    base = solve(prob_base, Tsit5())
    comp = solve(prob_comp, Tsit5(), callback=cb)

    time = comp.t
    detailed_time = LinRange(tspan..., 2000)

    plot(time, repeat([u_const], length(time)), ylim=[0, 3.5], label="duty cycle")
    plot!(detailed_time, pwm.(detailed_time, period, duty), label="input pwm")
    plot!(time, sys_comp.h.(comp.(time), u, time), label="composed")
    plot!(time, sys_base.h.(base.(time), u, time), label="baseline")
end

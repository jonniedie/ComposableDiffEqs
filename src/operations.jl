
# function Base.:+(sys1::NLStateSpace, sys2::NLStateSpace)
#     @assert(size(sys1) == size(sys2), "Systems have different shapes")
#     @assert(sys1.Ts == sys2.Ts, "Sampling time mismatch")
#
#     # f(x) = sys1.f(x[1:nstates(sys1)])
# end

function combine(f2::StateFunction, f1::StateFunction, h1::OutputFunction{true})
    function f!(dx, x, u, t)
        dx1, dx2, x1, x2 = @views dx[1], dx[2], x[1], x[2]
        y = h1(x1, u, t)
        f1(dx1, x1, u, t)
        f2(dx2, x2, y, t)
        return nothing
    end
end
combine(h2::OutputFunction{true}, h1::OutputFunction{true}) =
    OutputFunction((x, u, t) -> h2(x[2], h1(x[1], u, t), t))
combine(h2::OutputFunction{true}, h1::OutputFunction{false}) =
    OutputFunction((x, t) -> h2(x[2], h1(x[1], t), t))
combine(h2::OutputFunction{false}, h1) = OutputFunction((x, t) -> h2(x[2], t))

# Note reverse order of sys1 and sys2 because of right-to-left operation
function Base.:*(sys2::NLStateSpace, sys1::NLStateSpace)
    # Check that input/output dimensions and sampling times are compatable
    @assert(CS.ninputs(sys1) == CS.noutputs(sys2),
        "sys1 must have same number of inputs as sys2 has outputs"
    )
    @assert(sys1.Ts == sys2.Ts, "Sampling time mismatch")

    # Input/output dimensions
    nu = sys1.nu
    ny = sys2.ny

    # Initial conditions
    init = initial_conditions.([sys1, sys2])

    # New state function
    function _f!(dx, x, u, t)
        dx1, dx2, x1, x2 = @views dx[1], dx[2], x[1], x[2]
        y = sys1.h(x1, u, t)
        sys1.f(dx1, x1, u, t)
        sys2.f(dx2, x2, y, t)
        return nothing
    end
    f! = StateFunction(_f!, nu, init)

    # New output function
    h = combine(sys2.h, sys1.h)

    return NLStateSpace(f!, h, sys1.Ts)
end

abstract type DiscreteSource end

struct PulseTrain <: DiscreteSource
    amplitude
    period
    duty
end

struct Step <: DiscreteSource
    amplitude
    steptime
end

struct ContinuousSource
    func::Function
end

Source = Union{DiscreteSource, ContinuousSource}

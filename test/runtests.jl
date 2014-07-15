using ConfidenceWeighted
using Base.Test

using .SoftConfidenceWeighted

scw = SCWParameter(1.0, 1.0)

@test classify(scw, Dict()) == -1

@test_throws ErrorException update(scw, Dict(), -2)
@test_throws ErrorException update(scw, Dict(), 0)
@test_throws ErrorException update(scw, Dict(), 2)

@test scw == update(scw, Dict(), -1)
@test scw == update(scw, Dict(), 1)

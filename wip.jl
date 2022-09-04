using Pkg, Revise; Pkg.activate(".")
using PromClient
using Test

a = Int
b = Vector{a}
c = Dict{Set{Pair{String, String}}, b}()
PromClient._get_label_key_val
c[Set(["blah"=>"meh"])] = [1,2,3]

c
keys(c)

DEFAULT_BUCKETS = (.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, Inf)
# convert.(Int, DEFAULT_BUCKETS)
# floor.(Int, DEFAULT_BUCKETS)
typeof(DEFAULT_BUCKETS)
length(DEFAULT_BUCKETS)
[3 > b for b in DEFAULT_BUCKETS]

bucs = Tuple{Vararg{Float64}}((1.0,2.0,3.1))
typeof(bucs)
DEFAULT_BUCKETS isa Tuple{Vararg{Float64}}
issorted(DEFAULT_BUCKETS)
DEFAULT_BUCKETS[end] != Inf


# Hist tests:
# Move these to the metric tests
hist = HistogramMetric("testhist")
hist.buckets[end] == Inf

(1,2,3,4)

for i in 1:0.5:4
    println(i)
end

for i in 1:0.5:4
    println(i)
end

# bucket maker test
@test (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, Inf) == get_bucket_linear(1,0.5,4)

# (1.0, 2.1435469250725863, 3.348369522101714, 4.59479341998814, Inf) == get_bucket_exponential(1,1.1,4)
@test all((1.0, 2.1435469250725863, 3.348369522101714, 4.59479341998814, Inf) .≈ get_bucket_exponential(1,1.1,4))
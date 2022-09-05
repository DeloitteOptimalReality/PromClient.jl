using Pkg, Revise; Pkg.activate(".")
using PromClient
using Test

a = Int
b = Vector{a}
c = Dict{Set{Pair{String, String}}, b}()
PromClient._get_label_key_val
c[Set(["blah"=>"meh"])] = [1,2,3]
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

# hist.label_counts[Set([])] = get(hist.label_counts, Set([]), zeros(length(hist.buckets)))
# hist.label_counts[Set([])] = get(hist.label_counts, Set([]), zeros(length(hist.buckets))) .+ [3 <= b for b in hist.buckets]

# [3 <= b for b in hist.buckets]
# [9999 <= b for b in hist.buckets]
# [Inf <= b for b in hist.buckets]

###  Hist tests:
# Move these to the metric tests
failhist = HistogramMetric("testhist"; buckets=(0.4,0.1))
failhist = HistogramMetric("testhist"; buckets=(0.1))
hist = HistogramMetric("testhist")
@test hist.buckets[end] == Inf

observe(hist, 0.01)
observe(hist, 0.4)
observe(hist, 3)
observe(hist, 999)
# hist.buckets
@test hist.label_counts[Set()] == [3 <= b for b in hist.buckets] .+ [0.01 <= b for b in hist.buckets] .+ [0.4 <= b for b in hist.buckets] .+ [999 <= b for b in hist.buckets]
@test hist.label_sum[Set()] == 0.01 + 0.4 + 3 + 999

observe(hist, Inf)  # if this happens, average and other related calcs will break
inc(hist, 1)
@test_throws ErrorException inc(hist, [], 1)
@test_throws ErrorException set(hist, [], 1)
@test_throws ErrorException dec(hist, [], 1)

hist_labels = HistogramMetric("h_labs", "test histogram with labels", ["lab1", "lab2"]; buckets=(0.1,1.0,10.0,Inf))
test_observations = [0.05, 0.5, 5, 11]
for _o in test_observations
    observe(hist_labels, ["a","b"], _o)
end

_hlkv = PromClient._get_label_key_val(hist_labels, ["a","b"])
@test_throws ErrorException PromClient._get_label_key_val(hist_labels, ["a"])  # number of labels enforced now
# hist_labels.label_keys
@test hist_labels.label_counts[_hlkv] == [1.0, 2.0, 3.0, 4.0]
@test hist_labels.label_sum[_hlkv] == sum(test_observations)

test_labs2 = ["a", "c"]
test_obsr2 = [0.11, 0.75, 1, 5.5]
for _o in test_obsr2
    observe(hist_labels, test_labs2, _o)
end
hist_labels.buckets
_hlkv2 = PromClient._get_label_key_val(hist_labels, test_labs2)
@test hist_labels.label_counts[_hlkv2] == [0, 3.0, 4.0, 4.0]
@test hist_labels.label_sum[_hlkv2] == sum(test_obsr2)

# bucket maker test
@test (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, Inf) == get_bucket_linear(1,0.5,4)

# (1.0, 2.1435469250725863, 3.348369522101714, 4.59479341998814, Inf) == get_bucket_exponential(1,1.1,4)
@test all((1.0, 2.1435469250725863, 3.348369522101714, 4.59479341998814, Inf) .≈ get_bucket_exponential(1,1.1,4))

""" SuperClass of all Prometheus Metrics"""
abstract type PromMetric end

""" To be implemented """
abstract type SummaryMetric <: PromMetric end

"""
    CounterMetric

Struct to hold a prometheus counter metric

## Usage:
- Values must all be the same numeric type, defined by vtype upon struct creation.
- Label Keys should be pre-defined in label_keys before metrics are added. Modifying labels during runtime is NOT encouraged
- Labels are order Sensitive, when adding metrics

## Notes:
- Dict keys in label_data are implemented as sets of paired strings, look like this:
```
julia> a = Set(["a"=>"b", "c"=>"d"])
julia> b[a] = 10
julia> b[Set(["c"=>"d","a"=>"b"])] == b[Set(["a"=>"b","c"=>"d"])]  # true
````
"""
struct CounterMetric{VT <: Number, LT<: Base.AbstractLock} <: PromMetric
    name::String                    # Required for TYPE string
    descr::String                   # Description for HELP string, can be blank str
    label_keys::Vector{String}      # Ordered List of Possible Keys for use in labels
    label_data::Dict{Set{Pair{String, String}},VT}   # Dict that stores the data
    _vtype::Type                    # for storing the value type, useful for checking
    _lk::LT                         # lock
end
CounterMetric(n; vtype::Type=Int) = CounterMetric(n, "", Vector{String}(), Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())
CounterMetric(n, d; vtype::Type=Int) = CounterMetric(n, d, Vector{String}(), Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())
CounterMetric(n, d, labels::Vector{String}; vtype::Type=Int) = CounterMetric(n, d, labels, Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())

"""
    GaugeMetric

Struct to hold a prometheus gauge metrics. Functionally Same as Counter Metric, with added a dec function allowed
"""
struct GaugeMetric{VT <: Number, LT<: Base.AbstractLock} <: PromMetric
    name::String                    # Required for TYPE string
    descr::String                   # Description for HELP string, can be blank str
    label_keys::Vector{String}       # List of Possible Keys for use in labels
    label_data::Dict{Set{Pair{String, String}},VT}   # Dict that stores the data
    _vtype::Type                    # for storing the value type, useful for checking
    _lk::LT                         # lock
end
GaugeMetric(n; vtype::Type=Int) = GaugeMetric(n, "", Vector{String}(), Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())
GaugeMetric(n, d; vtype::Type=Int) = GaugeMetric(n, d, Vector{String}(), Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())
GaugeMetric(n, d, labels::Vector{String}; vtype::Type=Int) = GaugeMetric(n, d, labels, Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())


"""
    HistogramMetric

Struct to hold a prometheus gauge metrics. Functionally Same as Counter Metric, with added a dec function allowed
"""
struct HistogramMetric{VT <: Number, LT<: Base.AbstractLock} <: PromMetric
    name::String                    # Required for TYPE string
    descr::String                   # Description for HELP string, can be blank str
    label_keys::Vector{String}       # List of Possible Keys for use in labels
    label_data::Dict{Set{Pair{String, String}},VT}   # Dict that stores the data
    _vtype::Type                    # for storing the value type, useful for checking
    _lk::LT                         # lock
end
HistogramMetric(n; vtype::Type=Int) = HistogramMetric(n, "", Vector{String}(), Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())
HistogramMetric(n, d; vtype::Type=Int) = HistogramMetric(n, d, Vector{String}(), Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())
HistogramMetric(n, d, labels::Vector{String}; vtype::Type=Int) = HistogramMetric(n, d, labels, Dict{Set{Pair{String, String}}, vtype}(), vtype, Threads.ReentrantLock())

# A histogram MUST NOT allow le as a user-set label
# A histogram MUST offer a way to manually choose the buckets. 
# Buckets MUST NOT be changeable once the metric is created.
# A histogram must have a bucket with {le="+Inf"}. Its value must be identical to the value of x_count.
# The sample sum for a summary or histogram named x is given as a separate sample named x_sum.
#     The sample count for a summary or histogram named x is given as a separate sample named x_count.
#     Each bucket count of a histogram named x is given as a separate sample line with the name x_bucket and a label {le="y"} (where y is the upper bound of the bucket).
#     A histogram must have a bucket with {le="+Inf"}. Its value must be identical the the value of x_count
# The buckets of a histogram and the quantiles of a summary must appear in increasing numerical order of their label values (for the le or the quantile label, respectively).
DEFAULT_BUCKETS = (.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, Inf)


# helpers to print the struct type name

typename(::Type{T}) where {T} = (isempty(T.parameters) ? T : T.name.wrapper)

Base.show(io::IO, ::MIME"text/plain", a::PromMetric) = print(io, "$(typename(typeof(a))):$(a.name) labelKeys:$(a.label_keys)) ValueType:$(a._vtype)")
Base.show(io::IOBuffer, a::PromMetric) = print(io, a.name * ":" * typename(typeof(a))) # for string interpolation


""" 
    PromCollector

Collector is a collection of Metrics. Each metric is dentified by the name of the metric
Running Collect on the Collector returns the exposition
"""
struct PromCollector
    name::String
    metrics::Dict{String,PromMetric}
end
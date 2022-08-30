
""" SuperClass of all Prometheus Metrics"""
abstract type PromMetric end

""" To be implemented """
abstract type HistogramMetric <: PromMetric end
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

# helper to print the struct type name
typename(::Type{T}) where {T} = (isempty(T.parameters) ? T : T.name.wrapper)

Base.show(io::IO, ::MIME"text/plain", a::PromMetric) = print(io, "$(typename(typeof(a))):$(a.name) labelKeys:$(a.label_keys)) ValueType:$(a._vtype)")
Base.show(io::IOBuffer, a::PromMetric) = print(io, a.name * ":" * typename(typeof(a))) # for string interpolation


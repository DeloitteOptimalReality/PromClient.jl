
<a id='PromClient-Documentation'></a>

<a id='PromClient-Documentation-1'></a>

# PromClient Documentation

- [PromClient Documentation](index.md#PromClient-Documentation)
    - [Public Functions](index.md#Public-Functions)
    - [Private Functions](index.md#Private-Functions)


<a id='Public-Functions'></a>

<a id='Public-Functions-1'></a>

## Public Functions


These functions are exported by PromClient.

<a id='PromClient.CounterMetric' href='#PromClient.CounterMetric'>#</a>
**`PromClient.CounterMetric`** &mdash; *Type*.



```julia
CounterMetric
```

Struct to hold a prometheus counter metric.

**Usage:**

  * Values must all be the same numeric type, defined by vtype upon struct creation.
  * Label Keys should be pre-defined in label_keys before metrics are added. Modifying labels during runtime is NOT encouraged.
  * Labels are order Sensitive, when adding metrics.
  * Outputting timestamps are optional, therefore in order to retrieve timestamp log_timestamp kwarg must be set to True.

**Notes:**

  * Dict keys in label_data are implemented as sets of paired strings, look like this:

`julia> a = Set(["a"=>"b", "c"=>"d"]) julia> b[a] = 10 julia> b[Set(["c"=>"d","a"=>"b"])] == b[Set(["a"=>"b","c"=>"d"])]  # true``


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/types.jl#L8-L26' class='documenter-source'>source</a><br>

<a id='PromClient.GaugeMetric' href='#PromClient.GaugeMetric'>#</a>
**`PromClient.GaugeMetric`** &mdash; *Type*.



```julia
GaugeMetric
```

Struct to hold a prometheus gauge metrics. Functionally Same as Counter Metric, with added a dec function allowed.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/types.jl#L45-L49' class='documenter-source'>source</a><br>

<a id='PromClient.HistogramMetric' href='#PromClient.HistogramMetric'>#</a>
**`PromClient.HistogramMetric`** &mdash; *Type*.



```julia
HistogramMetric
```

Struct to hold Histogram Metrics. Different from Gauge/Counters as Each histogram label is a vector of metrics. Held in cumulative sum value for all observations that are larger than the specified bucket size.

Bucket sizes are specified by the 'le' label key, which is reserved. Observations are added using the  `observe` function, rather than `inc`, `set` or `dec`.

**Notes**

Properties of Histograms, from Prom Metrics Specifications: https://prometheus.io/docs/instrumenting/writing_clientlibs/#histogram

  * A histogram MUST NOT allow le as a user-set label
  * A histogram MUST offer a way to manually choose the buckets.
  * Buckets MUST NOT be changeable once the metric is created.
  * A histogram must have a bucket with {le="+Inf"}. Its value must be identical to the value of x_count.
  * The sample sum for a summary or histogram named x is given as a separate sample named x_sum.
  * ```
    The sample count for a summary or histogram named x is given as a separate sample named x_count.
    ```
  * ```
    Each bucket count of a histogram named x is given as a separate sample line with the name x_bucket and a label {le="y"} (where y is the upper bound of the bucket).
    ```
  * ```
    A histogram must have a bucket with {le="+Inf"}. Its value must be identical the the value of x_count
    ```
  * The buckets of a histogram and the quantiles of a summary must appear in increasing numerical order of their label values (for the le or the quantile label, respectively).


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/types.jl#L70-L92' class='documenter-source'>source</a><br>

<a id='PromClient.add_metric_to_collector!' href='#PromClient.add_metric_to_collector!'>#</a>
**`PromClient.add_metric_to_collector!`** &mdash; *Function*.



Adds the given metric to a given collector. uses the DEFAULT_COLLECTOR if non given.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/collectors.jl#L4' class='documenter-source'>source</a><br>

<a id='PromClient.collect-Tuple{CounterMetric}' href='#PromClient.collect-Tuple{CounterMetric}'>#</a>
**`PromClient.collect`** &mdash; *Method*.



```julia
collect(pm::PromMetric, mtype::String)
collect(pm::CounterMetric)
collect(pm::GaugeMetric)
```

Generates/formats the Prometheus scraping structure for the metrics endpoint.

Format as follows

```
# TYPE metric_name type
metric_name{label1=label_value1, label_key2=label_value2 ... } metric_value
metric_name{label1=label_value3, label_key2=label_value4 ... } metric_value
```

**Notes**

Unlike the input/metric functions, the output order of the labels is not garuanteed nor required by the Prometheus spec. For convenience this should be updated to ensure ordering.

**TODO**

Implement for others besides gauge and counter.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/exposition.jl#L13-L33' class='documenter-source'>source</a><br>

<a id='PromClient.dec' href='#PromClient.dec'>#</a>
**`PromClient.dec`** &mdash; *Function*.



Decrements the label for the Gauge metric by given amount.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L70' class='documenter-source'>source</a><br>

<a id='PromClient.generate_latest_collector_metrics' href='#PromClient.generate_latest_collector_metrics'>#</a>
**`PromClient.generate_latest_collector_metrics`** &mdash; *Function*.



```julia
generate_latest_collector_metrics(collector::PromCollector=DEFAULT_COLLECTOR)
```

Goes through the collector and formats data in all added metrics.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/exposition.jl#L1-L6' class='documenter-source'>source</a><br>

<a id='PromClient.get_bucket_linear-Tuple{Any, Any, Any}' href='#PromClient.get_bucket_linear-Tuple{Any, Any, Any}'>#</a>
**`PromClient.get_bucket_linear`** &mdash; *Method*.



```julia
Methods to Create histogram buckets
```

**Note**

You can create your own buckets, just needs to follow these rules:

  * Be an NTuple of Float64 (an Alias of Tuple{Vararg{Float64}})
  * Be in Ascending order
  * Last value in NTuple must be Inf


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L161-L169' class='documenter-source'>source</a><br>

<a id='PromClient.inc' href='#PromClient.inc'>#</a>
**`PromClient.inc`** &mdash; *Function*.



```julia
inc(pm::PromMetric, label_vals::Vector{String}, val::Number=1)
inc(pm::PromMetric, val::Number=1)
```

Increments the label for the metric by given amount.  If no label is provided, will add to blank label (empty set as key), but this is discouraged.

**Arguments**

```
- `pm::PromMetric`: reference to the Metric itself
- `label_vals::Vector{String}`: Vector of the label values, must be in order and 
matching the length of the label_keys of the metric
- `val::Number=1`: Value to increment by, defaults to 1. Use correct data type
```


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L34-L48' class='documenter-source'>source</a><br>

<a id='PromClient.observe-Tuple{HistogramMetric, Vector{String}, Number}' href='#PromClient.observe-Tuple{HistogramMetric, Vector{String}, Number}'>#</a>
**`PromClient.observe`** &mdash; *Method*.



```julia
observe(pm::HistogramMetric, label_vals::Vector{String}, val::Number)
observe(pm::HistogramMetric, val::Number)
```

Observe a value for histograms & Summaries, places it into the relevant bucket/quantile. Observation without label is only allowed if the metric itself was created without labels.

**TODO**

  * Implement observe for Summary Metrics.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L130-L140' class='documenter-source'>source</a><br>

<a id='PromClient.reset_metric!-Tuple{PromClient.PromMetric, Vector{String}}' href='#PromClient.reset_metric!-Tuple{PromClient.PromMetric, Vector{String}}'>#</a>
**`PromClient.reset_metric!`** &mdash; *Method*.



Resets label value for the metric to 0.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L114' class='documenter-source'>source</a><br>

<a id='PromClient.set-Tuple{PromClient.PromMetric, Vector{String}, Number}' href='#PromClient.set-Tuple{PromClient.PromMetric, Vector{String}, Number}'>#</a>
**`PromClient.set`** &mdash; *Method*.



Sets the label for the metric to some value. Should only be used on Gauges.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L86' class='documenter-source'>source</a><br>


<a id='Private-Functions'></a>

<a id='Private-Functions-1'></a>

## Private Functions


These functions are internal to PromClient.

<a id='PromClient.PromCollector' href='#PromClient.PromCollector'>#</a>
**`PromClient.PromCollector`** &mdash; *Type*.



```julia
PromCollector
```

Collector is a collection of Metrics. Each metric is dentified by the name of the metric. Running Collect on the Collector returns the exposition.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/types.jl#L146-L152' class='documenter-source'>source</a><br>

<a id='PromClient.PromMetric' href='#PromClient.PromMetric'>#</a>
**`PromClient.PromMetric`** &mdash; *Type*.



SuperClass of all Prometheus Metrics.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/types.jl#L2' class='documenter-source'>source</a><br>

<a id='PromClient.SummaryMetric' href='#PromClient.SummaryMetric'>#</a>
**`PromClient.SummaryMetric`** &mdash; *Type*.



To be implemented.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/types.jl#L5' class='documenter-source'>source</a><br>

<a id='PromClient._get_label_key_val-Tuple{PromClient.PromMetric, Vector{String}}' href='#PromClient._get_label_key_val-Tuple{PromClient.PromMetric, Vector{String}}'>#</a>
**`PromClient._get_label_key_val`** &mdash; *Method*.



```julia
_get_label_key_val(pm::PromMetric, label_vals::Vector{String})
_get_label_key_val(pm::PromMetric)
```

Helper to get the keys needed in the label_data dict  only allow no labels vals, if no label keys exist.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L13-L20' class='documenter-source'>source</a><br>

<a id='PromClient._prometheus_format_label-Tuple{String, Set{Pair{String, String}}, Number}' href='#PromClient._prometheus_format_label-Tuple{String, Set{Pair{String, String}}, Number}'>#</a>
**`PromClient._prometheus_format_label`** &mdash; *Method*.



```julia
_prometheus_format_label()
```

Formats a single prom metric text line, using the specified label pairs in the format of metric*name{labels=label*value}value.

**Input**

```
`pm::PromMetric`: The metric object, used to determine the tyupe of formatting used.
`label_pair`: The label pair(s) to be printed/formatted.
`metric_val`: The value of the metric.
`bucket`: For Histogram only, used to set the bucket/le key/label pair.
`m_suffix`: For Histogram/Summaries, used to set the suffix after the metric name.
```

**Examples**


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/exposition.jl#L68-L82' class='documenter-source'>source</a><br>

<a id='PromClient._update_timestamp-Tuple{PromClient.PromMetric, Set{Pair{String, String}}}' href='#PromClient._update_timestamp-Tuple{PromClient.PromMetric, Set{Pair{String, String}}}'>#</a>
**`PromClient._update_timestamp`** &mdash; *Method*.



```julia
_update_timestamp(pm::Prometric, label_key_val::Dict{Set{Pair{String, String}},VT})
```

Updates the timestamp for a key value pair if pm.log_timestamp is true.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L1-L5' class='documenter-source'>source</a><br>

<a id='PromClient.datetime2epoch-Tuple{Dates.DateTime}' href='#PromClient.datetime2epoch-Tuple{Dates.DateTime}'>#</a>
**`PromClient.datetime2epoch`** &mdash; *Method*.



```julia
datetime2epoch(dt::DateTime) -> Int64
```

Take the given `DateTime` and return the number of seconds since the unix epoch `1970-01-01T00:00:00` as a [`Int64`](@ref).


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/utilities.jl#L1-L6' class='documenter-source'>source</a><br>

<a id='PromClient.set_to_current_time-Tuple{GaugeMetric, Vector{String}}' href='#PromClient.set_to_current_time-Tuple{GaugeMetric, Vector{String}}'>#</a>
**`PromClient.set_to_current_time`** &mdash; *Method*.



Sets a gauge to the current unixtime, in seconds.


<a target='_blank' href='https://github.com/spcogg/PromClient.jl/blob/dc9b41dd506da5903995163c10e0ada555015a5a/src/metrics.jl#L108' class='documenter-source'>source</a><br>


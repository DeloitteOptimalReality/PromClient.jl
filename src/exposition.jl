""" 
    generate_latest_collector_metrics(collector::PromCollector=DEFAULT_COLLECTOR)

Goes through the collector and formats data in all added metrics.
"""
function generate_latest_collector_metrics(collector::PromCollector=DEFAULT_COLLECTOR)
    latest_str = [collect(m) for (_, m) in collector.metrics]
    return join(latest_str)
end



"""
    collect(pm::PromMetric, mtype::String)
    collect(pm::CounterMetric)
    collect(pm::GaugeMetric)

Generates/formats the Prometheus scraping structure for the metrics endpoint.


Format as follows
```
# TYPE metric_name type
metric_name{label1=label_value1, label_key2=label_value2 ... } metric_value
metric_name{label1=label_value3, label_key2=label_value4 ... } metric_value
```
# Notes
Unlike the input/metric functions, the output order of the labels is not garuanteed nor required
by the Prometheus spec. For convenience this should be updated to ensure ordering.

# TODO 
Implement for others besides gauge and counter.
"""
function collect(pm::CounterMetric)
    return collect(pm, "counter")
end
function collect(pm::GaugeMetric)
    return collect(pm, "gauge")
end
function collect(pm::Union{CounterMetric, GaugeMetric}, mtype::String)
        latest_str = ["$(_prometheus_format_label(pm, l, v)) \n" for (l,v) in pm.label_data]
        return """
        # HELP $(pm.name) $(pm.desc)
        # TYPE $(pm.name) $mtype
        $(join(latest_str))
        """
end
function collect(pm::HistogramMetric)
    latest_str = []
    for (_lab, lab_counts) in pm.label_counts
        for (i,_b) in enumerate(pm.buckets)
            b_val = lab_counts[i]
            push!(latest_str, "$(_prometheus_format_label(pm, _lab, b_val, _b))")
        end
        lab_count = lab_counts[end]
        push!(latest_str, "$(_prometheus_format_label(pm, _lab, lab_count, nothing; m_suffix="count"))")
        lab_sum = pm.label_sum[_lab]
        push!(latest_str, "$(_prometheus_format_label(pm, _lab, lab_sum, nothing; m_suffix="sum"))")
    end
    return """
    # HELP $(pm.name) $(pm.desc)
    # TYPE $(pm.name) histogram
    $(join(latest_str, "\n"))
    
    """
end

"""
    _prometheus_format_label()
Formats a single prom metric text line, using the specified label pairs
in the format of metric_name{labels=label_value}value.

# Input
    `pm::PromMetric`: The metric object, used to determine the tyupe of formatting used.
    `label_pair`: The label pair(s) to be printed/formatted.
    `metric_val`: The value of the metric.
    `bucket`: For Histogram only, used to set the bucket/le key/label pair.
    `m_suffix`: For Histogram/Summaries, used to set the suffix after the metric name.

# Examples

"""
function _prometheus_format_label(metric_name::String, label_pair::Set{Pair{String, String}}, metric_val::Number; bucket=nothing)
    _prom_labels = join(["$lk=\"$lv\"" for (lk,lv) in label_pair], ",")
    if !isnothing(bucket)  # bucket key/val label must be at the end
        _prom_labels = "$_prom_labels,le=\"$bucket\""
    end
    return "$(metric_name){$_prom_labels} $(string(metric_val))"
end
function _prometheus_format_label(pm::Union{CounterMetric, GaugeMetric}, label_pair::Set{Pair{String, String}}, metric_val::Number)
    output = _prometheus_format_label(pm.name, label_pair, metric_val)
    if pm.log_timestamp
        output = output * " $(pm.label_timestamp[label_pair])"
    end
    return output
end
function _prometheus_format_label(pm::HistogramMetric, label_pair::Set{Pair{String, String}}, metric_val::Number, bucket::Union{Number, Nothing}; m_suffix::String="bucket")
    metric_name = "$(pm.name)_$m_suffix"
    output = _prometheus_format_label(metric_name, label_pair, metric_val; bucket=bucket)
    if pm.log_timestamp
        output = output * " $(pm.label_timestamp[label_pair])"
    end
    return output
end

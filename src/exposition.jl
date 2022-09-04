""" 
    generate_latest_collector_metrics(collector::PromCollector=DEFAULT_COLLECTOR)

goes through the collector and formats data in all added metrics
"""
# function generate_latest_collector_metrics(collector::Vector{PromMetric}=DEFAULT_COLLECTOR)
function generate_latest_collector_metrics(collector::PromCollector=DEFAULT_COLLECTOR)
    latest_str = [collect(m) for m in collector.metrics]
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
by the Prometheus spec. For convenience this should be updated to ensure ordering

# TODO 
implement for others besides gauge and counter
"""
function collect(pm::CounterMetric)
    return collect(pm, "counter")
end
function collect(pm::GaugeMetric)
    return collect(pm, "gauge")
end
function collect(pm::PromMetric, mtype::String)
        latest_str = ["$(_prometheus_format_label(pm.name, l,v)) \n" for (l,v) in pm.label_data]
        return """
        # HELP $(pm.name) $(pm.descr)
        # TYPE $(pm.name) $mtype
        $(join(latest_str))
        """
end

"""
    _prometheus_format_label()
Formats a single prom metric with one or more label pairs, 
in the format of metric_name{labels=label_value}value 

# Input

# Examples

"""
function _prometheus_format_label(metric_name::String, label_pair::Set{Pair{String, String}}, metric_val::Number)
    _prom_labels = join(["$lk=\"$lv\"" for (lk,lv) in label_pair], ",")
    return "$metric_name{$_prom_labels} $(string(metric_val))"
end

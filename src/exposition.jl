""" 
    generate_latest_prom_metrics(collector::Vector=DEFAULT_COLLECTOR)

goes through the collector and formats data in all added metrics
"""
function generate_latest_prom_metrics(collector::Vector=DEFAULT_COLLECTOR)
    latest_str = [_prometheus_format(m) for m in collector]
    return join(latest_str)
end



"""
    _prometheus_format(pm::PromMetric, mtype::String)
    _prometheus_format(pm::CounterMetric)
    _prometheus_format(pm::GaugeMetric)

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
function _prometheus_format(pm::CounterMetric)
    return _prometheus_format(pm, "counter")
end
function _prometheus_format(pm::GaugeMetric)
    return _prometheus_format(pm, "gauge")
end
function _prometheus_format(pm::PromMetric, mtype::String)
        latest_str = ["$(_prometheus_format_label(pm.name, l,v)) \n" for (l,v) in pm.label_data]
        return """
        # HELP $(pm.name) $(pm.descr)
        # TYPE $(pm.name) $mtype
        $(join(latest_str))
        """
end

"""Formats a single prom metric with one or more label pairs, in the format of metric_name{labels=label_value}value """
function _prometheus_format_label(metric_name::String, label_pair::Set{Pair{String, String}}, metric_val::Number)
    _prom_labels = join(["$lk=\"$lv\"" for (lk,lv) in label_pair], ",")
    return "$metric_name{$_prom_labels} $(string(metric_val))"
end

""" 
    generate_pretty_prom_metrics(collector::Vector=DEFAULT_COLLECTOR)

goes through the collector and formats data in all added metrics into a pretty format for logging
"""
function generate_pretty_prom_metrics(collector::Vector=DEFAULT_COLLECTOR)
    latest_str = [_prometheus_pretty(m) for m in collector]
    return join(latest_str)
end


"""
    _prometheus_pretty(pm::PromMetric, mtype::String)
    _prometheus_pretty(pm::CounterMetric)
    _prometheus_pretty(pm::GaugeMetric)

Generates/formats the Prometheus scraping structure for the metrics endpoint.


Format as follows
```
metric_descr (label_value_1, ): value
metric_descr (label_value_3, ): value
```
# Notes
Unlike the input/metric functions, the output order of the labels is not garuanteed nor required
by the Prometheus spec. For convenience this should be updated to ensure ordering

# TODO 
implement for others besides gauge and counter
"""
function _prometheus_pretty(pm::CounterMetric)
    return _prometheus_pretty(pm, "counter")
end
function _prometheus_pretty(pm::GaugeMetric)
    return _prometheus_pretty(pm, "gauge")
end
function _prometheus_pretty(pm::PromMetric, mtype::String)
        latest_str = ["$(_prometheus_pretty_label(pm.descr, l,v)) \n" for (l,v) in pm.label_data]
        return """
        $(join(latest_str))
        """
end

"""Formats a single prom metric with one or more label pairs, in the format of `metric_descr (label_value, ): value`"""
function _prometheus_pretty_label(metric_descr::String, label_pair::Set{Pair{String, String}}, metric_val::Number)
    _prom_labels = join(["$lv" for (_, lv) in label_pair], ", ")
    return "$metric_descr ($_prom_labels): $(string(metric_val))"
end
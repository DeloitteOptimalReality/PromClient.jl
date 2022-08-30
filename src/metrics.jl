
""" 
    _get_label_key_val(pm::PromMetric, label_vals::Vector{String})

Helper to get the keys needed in the label_data dict 

# Notes
If there are less label values provided than keys defined, it will use them in order and stop
Cannot be more label values provided than there are labels defined.
"""
_get_label_key_val(pm::PromMetric, label_vals::Vector{String}) = Set([pm.label_keys[i]=>label for (i,label) in enumerate(label_vals)])

""" 
    inc(pm::PromMetric, label_vals::Vector{String}, val::Number=1)
    inc(pm::PromMetric, val::Number=1)

Increments the label for the metric by given amount. 
If no label is provided, will add to blank label (empty set as key), but this is discouraged

# Arguments
    - `pm::PromMetric`: reference to the Metric itself
    - `label_vals::Vector{String}`: Vector of the label values, must be in order and 
    matching the length of the label_keys of the metric
    - `val::Number=1`: Value to increment by, defaults to 1. Use correct data type
    
"""
function inc(pm::PromMetric, label_vals::Vector{String}, val::Number=1)
    # does no validation of the sign of the number, up to user to make sure you don't pass in a negative
    _label_key_val = _get_label_key_val(pm, label_vals)
    try
        lock(pm._lk)
        if haskey(pm.label_data, _label_key_val)
            pm.label_data[_label_key_val] += val
        else
            pm.label_data[_label_key_val] = val
        end
    finally
        unlock(pm._lk)
    end
end
function inc(pm::PromMetric, val::Number=1)
    inc(pm, String[], val)  # blank labels, this is discouraged
end

""" Decrements the label for the Gauge metric by given amount. See set() for help"""
function dec(pm::GaugeMetric, label_vals::Vector{String}, val::Number=1)
    inc(pm, label_vals, -1 * val)  # just a negative inc
end
function dec(pm::PromMetric, val::Number=1)
    dec(pm, String[], val)  # blank labels, this is discouraged
end


""" Sets the label for the metric to some value. Should only be used on Gauges."""
function set(pm::PromMetric, label_vals::Vector{String}, val::Number)
    _label_key_val = _get_label_key_val(pm, label_vals)
    try
        lock(pm._lk)
        pm.label_data[_label_key_val] = val
    finally
        unlock(pm._lk)
    end
end
function set(pm::PromMetric, val::Number=1)
    set(pm, String[], val)  # blank labels, this is discouraged
end


""" Resets label value for the metric to 0."""
function reset_metric(pm::PromMetric, label_vals::Vector{String})
    set(pm, label_vals, 0)
end
function reset_metric(pm::PromMetric)
    reset_metric(pm, String[])  # blank labels, this is discouraged
end
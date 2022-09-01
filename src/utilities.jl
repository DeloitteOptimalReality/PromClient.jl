"""
    datetime2epoch(dt::DateTime) -> Int64

Take the given `DateTime` and return the number of seconds
since the unix epoch `1970-01-01T00:00:00` as a [`Int64`](@ref).
"""
datetime2epoch(dt::DateTime) = Dates.value(dt) - Dates.UNIXEPOCH
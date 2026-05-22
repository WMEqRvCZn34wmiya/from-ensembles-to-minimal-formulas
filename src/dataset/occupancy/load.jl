using CSV, DataFrames

data_path = joinpath(@__DIR__, "occupancy.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "occupancy.csv")

col_names = [
    :id,
    :date,
    :temperature,
    :humidity,
    :light,
    :co2,
    :humidity_ratio,
    :occupancy
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not([:id, :date]))
CSV.write(df_path, df)
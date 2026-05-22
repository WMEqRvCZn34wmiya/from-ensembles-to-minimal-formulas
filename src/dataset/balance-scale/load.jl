using CSV, DataFrames

data_path = joinpath(@__DIR__, "balance-scale.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "balance-scale.csv")

col_names = [
    :class,
    :left_weight,
    :left_distance,
    :right_weight,
    :right_distance,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class), :class)
CSV.write(df_path, df)
using CSV, DataFrames

data_path = joinpath(@__DIR__, "transfusion.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "transfusion.csv")

col_names = [
    :recency,
    :frequency,
    :monetary,
    :time,
    :class
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

# Keep class as last column
select!(df, Not(:class), :class)

CSV.write(df_path, df)
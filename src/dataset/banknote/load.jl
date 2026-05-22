using CSV, DataFrames

data_path = joinpath(@__DIR__, "banknote.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "banknote.csv")

col_names = [
    :variance,
    :skewness,
    :curtosis,
    :entropy,
    :class,
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
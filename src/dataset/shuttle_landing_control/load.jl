using CSV, DataFrames

data_path = joinpath(@__DIR__, "shuttle-landing-control.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "shuttle-landing-control.csv")

col_names = [
    :class,
    :stability,
    :error,
    :sign,
    :wind,
    :magnitude,
    :visibility
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
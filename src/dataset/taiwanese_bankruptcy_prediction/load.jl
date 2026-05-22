using CSV, DataFrames

data_path = joinpath(@__DIR__, "data.csv")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "taiwanese_bankruptcy_prediction.csv")

df = CSV.read(
    data_path,
    DataFrame;
    missingstring="?",
    stripwhitespace=true,
)

# Move first column ("class" / "Bankrupt?") to the last position
select!(df, Not(1), 1)

CSV.write(df_path, df)
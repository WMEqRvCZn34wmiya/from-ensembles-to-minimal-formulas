using CSV, DataFrames

data_path = joinpath(@__DIR__, "ionosphere.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "ionosphere.csv")

col_names = [Symbol("v$i") for i in 1:34]
push!(col_names, :class)

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)
using CSV, DataFrames

out_dir = joinpath(@__DIR__, "..", "..", "dataframes")
mkpath(out_dir)

col_names = [:class, :a1, :a2, :a3, :a4, :a5, :a6, :id]

data_path = joinpath(@__DIR__, "monks-1.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "monks-1.csv")

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class, :id), :class)
CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "monks-2.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "monks-2.csv")

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class, :id), :class)
CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "monks-3.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "monks-3.csv")

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class, :id), :class)
CSV.write(df_path, df)

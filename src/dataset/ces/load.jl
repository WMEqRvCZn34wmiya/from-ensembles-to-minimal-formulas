using CSV, DataFrames

data_path = joinpath(@__DIR__, "ces-small1.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "ces-small1.csv")

col_names = [
    :f1,
    :f2,
    :f3,
    :f4,
    :f5,
    :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "ces-small1.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "ces-small2.csv")

col_names = [
    :f1,
    :f2,
    :f3,
    :f4,
    :f5,
    :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)
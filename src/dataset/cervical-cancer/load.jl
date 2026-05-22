using CSV, DataFrames

data_path = joinpath(@__DIR__, "cervical-cancer-behavior-risk.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "cervical-cancer-behavior-risk.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :f19,
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
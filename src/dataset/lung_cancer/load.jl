using CSV, DataFrames

data_path = joinpath(@__DIR__, "lung-cancer.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "lung_cancer.csv")


# class is column 1, then V2..V57
col_names = [:class; Symbol.("V" .* string.(2:57))]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class), :class)
CSV.write(df_path, df)
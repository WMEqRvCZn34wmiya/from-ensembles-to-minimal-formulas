using CSV, DataFrames

data_path = joinpath(@__DIR__, "breast-tissue.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "breast-tissue.csv")

col_names = [
    :class,
    :i0,
    :pa500,
    :hfs,
    :da,
    :area,
    :a_div_da,
    :max_ip,
    :dr,
    :p,
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
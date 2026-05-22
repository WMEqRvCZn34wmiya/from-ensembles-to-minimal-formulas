using CSV, DataFrames

data_path = joinpath(@__DIR__, "ecoli.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "ecoli.csv")

# ecoli.data is typically space-separated
col_names = [
    :sequence_name,
    :mcg,
    :gvh,
    :lip,
    :chg,
    :aac,
    :alm1,
    :alm2,
    :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    delim=' ',
    ignorerepeated=true,
)

select!(df, Not(:sequence_name))
CSV.write(df_path, df)
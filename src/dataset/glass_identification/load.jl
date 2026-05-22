using CSV, DataFrames

data_path = joinpath(@__DIR__, "glass.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "glass_identification.csv")

col_names = [
    :id,
    :ri,
    :na,
    :mg,
    :al,
    :si,
    :k,
    :ca,
    :ba,
    :fe,
    :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:id))
CSV.write(df_path, df)
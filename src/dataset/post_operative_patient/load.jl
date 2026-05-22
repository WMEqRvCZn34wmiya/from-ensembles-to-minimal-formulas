using CSV, DataFrames

data_path = joinpath(@__DIR__, "post-operative.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "post_operative_patient.csv")

mkpath(dirname(df_path))

col_names = [
    :l_core,
    :l_surf,
    :l_o2,
    :l_bp,
    :surf_stbl,
    :core_stbl,
    :bp_stbl,
    :comfort,
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
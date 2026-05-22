using CSV, DataFrames

data_path = joinpath(@__DIR__, "seeds.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "seeds.csv")

col_names = [
    :area,
    :perimeter,
    :compactness,
    :length,
    :width,
    :asymmetry,
    :groove_length,
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
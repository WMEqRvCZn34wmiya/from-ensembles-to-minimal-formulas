using CSV, DataFrames

data_path = joinpath(@__DIR__, "lenses.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "lenses.csv")

col_names = [
    :age,
    :spectacle_prescription,
    :astigmatic,
    :tear_production_rate,
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
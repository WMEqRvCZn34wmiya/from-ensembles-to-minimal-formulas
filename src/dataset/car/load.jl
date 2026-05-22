using CSV, DataFrames

data_path = joinpath(@__DIR__, "car.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "car.csv")

col_names = [
    :buying,
    :maint,
    :doors,
    :persons,
    :lug_boot,
    :safety,
    :class
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)
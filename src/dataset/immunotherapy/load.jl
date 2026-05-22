using CSV, DataFrames

data_path = joinpath(@__DIR__, "immunotherapy.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "immunotherapy.csv")

col_names = [
    :sex,
    :age,
    :time,
    :number_of_warts,
    :type,
    :area,
    :induration_diameter,
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
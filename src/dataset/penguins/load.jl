using CSV, DataFrames

data_path = joinpath(@__DIR__, "penguins.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "penguins.csv")

col_names = [
    :class, # species
    :island,
    :bill_length_mm,
    :bill_depth_mm,
    :flipper_length,
    :body_mass_g,
    :sex,
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class), :class)
CSV.write(df_path, df)
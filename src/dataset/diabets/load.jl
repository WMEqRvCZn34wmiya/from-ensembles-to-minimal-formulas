using CSV, DataFrames

data_path = joinpath(@__DIR__, "diabets.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "diabets.csv")

col_names = [
    :pregnancies,
    :glucose,
    :blood_pressure,
    :skin_thickness,
    :insulin,
    :bmi,
    :diabetes_pedigree_function,
    :age,
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
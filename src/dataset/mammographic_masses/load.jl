using CSV, DataFrames

data_path = joinpath(@__DIR__, "mammographic_masses.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "mammographic_masses.csv")

col_names = [
    :bi_rads_assessment,
    :age,
    :shape,
    :margin,
    :density,
    :class,  # severity: benign=0, malignant=1
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)
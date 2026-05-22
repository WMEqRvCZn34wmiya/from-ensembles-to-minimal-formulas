using CSV, DataFrames

data_path = joinpath(@__DIR__, "hepatitis.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "hepatitis.csv")

col_names = [
    :class,
    :age,
    :sex,
    :steroid,
    :antivirals,
    :fatigue,
    :malaise,
    :anorexia,
    :liver_big,
    :liver_firm,
    :spleen_palpable,
    :spiders,
    :ascites,
    :varices,
    :bilirubin,
    :alk_phosphate,
    :sgot,
    :albumin,
    :protime,
    :histology,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class), :class)
CSV.write(df_path, df)
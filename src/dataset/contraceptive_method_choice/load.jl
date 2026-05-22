using CSV, DataFrames

data_path = joinpath(@__DIR__, "cmc.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "contraceptive_method_choice.csv")

col_names = [
    :wife_age,
    :wife_education,
    :husband_education,
    :number_of_children_ever_born,
    :wife_religion,
    :wife_now_working,
    :husband_occupation,
    :standard_of_living_index,
    :media_exposure,
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
using CSV, DataFrames

data_path = joinpath(@__DIR__, "primary-tumor.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "primary_tumor.csv")

col_names = [
    :class,
    :age,
    :sex,
    :histologic_type,
    :degree_of_diffe,
    :bone,
    :bone_marrow,
    :lung,
    :pleura,
    :peritoneum,
    :liver,
    :brain,
    :skin,
    :neck,
    :supraclavicular,
    :axillar,
    :mediastinum,
    :abdominal,
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
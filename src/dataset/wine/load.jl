using CSV, DataFrames

data_path = joinpath(@__DIR__, "wine.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "wine.csv")

mkpath(dirname(df_path))

col_names = [
    :class,
    :alcohol,
    :malic_acid,
    :ash,
    :alcalinity_of_ash,
    :magnesium,
    :total_phenols,
    :flavanoids,
    :nonflavanoid_phenols,
    :proanthocyanins,
    :color_intensity,
    :hue,
    :od280_od315_of_diluted_wines,
    :proline,
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
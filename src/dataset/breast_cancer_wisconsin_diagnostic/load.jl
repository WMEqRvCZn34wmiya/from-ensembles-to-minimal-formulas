using CSV, DataFrames

data_path = joinpath(@__DIR__, "wdbc.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "breast_cancer_wisconsin_diagnostic.csv")

col_names = [
    :id,      # remove
    :class,   # move to last
    :mean_radius, :mean_texture, :mean_perimeter, :mean_area, :mean_smoothness,
    :mean_compactness, :mean_concavity, :mean_concave_points, :mean_symmetry, :mean_fractal_dimension,
    :radius_se, :texture_se, :perimeter_se, :area_se, :smoothness_se,
    :compactness_se, :concavity_se, :concave_points_se, :symmetry_se, :fractal_dimension_se,
    :worst_radius, :worst_texture, :worst_perimeter, :worst_area, :worst_smoothness,
    :worst_compactness, :worst_concavity, :worst_concave_points, :worst_symmetry, :worst_fractal_dimension,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

# Remove ID and keep class as the last column
select!(df, Not([:id, :class]), :class)

CSV.write(df_path, df)
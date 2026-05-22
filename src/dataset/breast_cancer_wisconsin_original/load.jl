using CSV, DataFrames

data_path = joinpath(@__DIR__, "breast-cancer-wisconsin.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "breast-cancer-wisconsin.csv")

bc_cols = [
    :sample_code_number,          # remove
    :clump_thickness,
    :uniformity_of_cell_size,
    :uniformity_of_cell_shape,
    :marginal_adhesion,
    :single_epithelial_cell_size,
    :bare_nuclei,
    :bland_chromatin,
    :normal_nucleoli,
    :mitoses,
    :class,
]

df_bc = CSV.read(
    data_path,
    DataFrame;
    header=bc_cols,
    missingstring="?",
    stripwhitespace=true,
)

select!(df_bc, Not(:sample_code_number))
CSV.write(df_path, df_bc)

data_path = joinpath(@__DIR__, "wdbc.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "wdbc.csv")

wdbc_cols = [
    :id,                          # remove
    :class,                       # move to last
    :mean_radius, :mean_texture, :mean_perimeter, :mean_area, :mean_smoothness,
    :mean_compactness, :mean_concavity, :mean_concave_points, :mean_symmetry, :mean_fractal_dimension,
    :radius_se, :texture_se, :perimeter_se, :area_se, :smoothness_se,
    :compactness_se, :concavity_se, :concave_points_se, :symmetry_se, :fractal_dimension_se,
    :worst_radius, :worst_texture, :worst_perimeter, :worst_area, :worst_smoothness,
    :worst_compactness, :worst_concavity, :worst_concave_points, :worst_symmetry, :worst_fractal_dimension,
]

df_wdbc = CSV.read(
    data_path,
    DataFrame;
    header=wdbc_cols,
    stripwhitespace=true,
)

select!(df_wdbc, Not([:id, :class]), :class)
CSV.write(df_path, df_wdbc)

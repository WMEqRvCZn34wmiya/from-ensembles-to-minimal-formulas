using CSV, DataFrames

data_path = joinpath(@__DIR__, "mushroom.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "mushroom.csv")

col_names = [
    :class,
    :cap_shape,
    :cap_surface,
    :cap_color,
    :bruises,
    :odor,
    :gill_attachment,
    :gill_spacing,
    :gill_size,
    :gill_color,
    :stalk_shape,
    :stalk_root,
    :stalk_surface_above_ring,
    :stalk_surface_below_ring,
    :stalk_color_above_ring,
    :stalk_color_below_ring,
    :veil_type,
    :veil_color,
    :ring_number,
    :ring_type,
    :spore_print_color,
    :population,
    :habitat,
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
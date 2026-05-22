using CSV, DataFrames

data_path = joinpath(@__DIR__, "avila.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "avila.csv")

col_names = [
    :kursi,
    :weight,
    :height,
    :acute_angle,
    :class_angle,
    :curve,
    :connect_curves,
    :blackpixels,
    :blackpixels_y,
    :blackpixels_x,
    :class
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)
using CSV, DataFrames

data_path = joinpath(@__DIR__, "dry-bean.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "dry_bean.csv")

col_names = [
    :Area, :Perimeter, :MajorAxisLength, :MinorAxisLength,
    :AspectRation, :Eccentricity, :ConvexArea, :EquivDiameter,
    :Extent, :Solidity, :Roundness, :Compactness,
    :ShapeFactor1, :ShapeFactor2, :ShapeFactor3, :ShapeFactor4,
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
using CSV, DataFrames

data_path = joinpath(@__DIR__, "veichle.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_A.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_A.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_B.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_B.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_C.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_C.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_D.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_D.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_F.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_F.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_G.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_G.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_H.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_H.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle_I.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle_I.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)

data_path = joinpath(@__DIR__, "veichle.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "veichle.csv")

col_names = [
    :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10,
    :f11, :f12, :f13, :f14, :f15, :f16, :f17, :f18, :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)
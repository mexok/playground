df = spark.createDataFrame([
    [0, 1, 2, 3],
    [4, 5, 6, 7],
])
print(df.count())

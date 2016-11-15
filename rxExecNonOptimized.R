# Open source package for creating data tables, will be used to create random data
library(data.table)

# Open source package That we will use to verify the results of rxExec()
library(foreach)

# Our dataset will have 5 million rows
nrow <- 5e6

# Create a data table with 5 million row, 3 columns (A random letter between ‘A’ 
# and ‘G and two random deviates based on the row number)
test.data  <- data.table(tag = sample(LETTERS[1:7], nrow, replace = T), a = runif(nrow), b = runif(nrow))

# Run the following line if you wish to verify the dimensions of the created table 
# are 5 million by 3
dim(test.data) 

# Next, we want to get all unique values in the first column, there is not guarantee 
# that all letters A – G were used
tags <- unique(test.data$tag)

# Now lets define a function to take the subset of rows, based on the value in the first 
# column, and take the sum of data column “a” of all of these rows
subsetSums <- function(data, tags) {
    x <- subset(data, tag == tags)
    sum(x$a)
}

# First let’s run this using Foreach, which will iterate through every tag sequentially 
# and take the sums of the provided data columns.
resForeach <- foreach( tag = iter(tags) ) %do% {
    subsetSums (test.data, tag)
}

# We’re going to use rxExec() to parallelize the above function, running each sum on a core of our machine
# rxExec is wrapped in system.time() to measure it’s performance, cat('MKL Threads=',getMKLthreads(),'\n') 
# will tell us how man simultaneous sums we can perform. Breaking down the rxExec() call, we have specified 
# the function “subsetSums”, and it’s two imput parameters, data getting test.data, and tags getting tags 
# wrapped in rxElemArg() which will give each parallel execution of “subsetSums” its own tag to operate on

system.time({
  cat('MKL Threads=',getMKLthreads(),'\n') 
  rxSetComputeContext("localpar")
  resRxExec <- rxExec(subsetSums, test.data, rxElemArg(tags))
})

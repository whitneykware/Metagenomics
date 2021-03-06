library(dada2); packageVersion("dada2")


# File parsing
pathF <- "/Users/whitneyware/IER_Sleeve/IER_Run_2_seqs/fwd"
pathR <- "/Users/whitneyware/IER_Sleeve/IER_Run_2_seqs/rev"
filtpathF <- file.path(pathF, "filtered") 
filtpathR <- file.path(pathR, "filtered") 
fastqFs <- sort(list.files(pathF, pattern="fastq.gz"))
fastqRs <- sort(list.files(pathR, pattern="fastq.gz"))
if(length(fastqFs) != length(fastqRs)) stop("Forward and reverse files do not match.")

# Filtering: THESE PARAMETERS ARENT OPTIMAL FOR ALL DATASETS
filterAndTrim(fwd=file.path(pathF, fastqFs), filt=file.path(filtpathF, fastqFs),
              rev=file.path(pathR, fastqRs), filt.rev=file.path(filtpathR, fastqRs),
              truncLen=c(100,130), maxEE=2, truncQ=11, maxN=0, rm.phix=TRUE,
              compress=TRUE, verbose=TRUE, trimLeft = c(20, 18))

# File parsing
filtpathF <- "/Users/whitneyware/IER_Sleeve/IER_Run_2_seqs/fwd/filtered" 
filtpathR <- "/Users/whitneyware/IER_Sleeve/IER_Run_2_seqs/rev/filtered"
filtFs <- list.files(filtpathF, pattern="fastq.gz", full.names = TRUE)
filtRs <- list.files(filtpathR, pattern="fastq.gz", full.names = TRUE)
sample.names <- sapply(strsplit(basename(filtFs), "-"), `[`, 1) 
sample.namesR <- sapply(strsplit(basename(filtRs), "-"), `[`, 1) 
if(!identical(sample.names, sample.namesR)) stop("Forward and reverse files do not match.")
names(filtFs) <- sample.names
names(filtRs) <- sample.names
set.seed(100)

# Learn forward error rates
errF <- learnErrors(filtFs)
# Learn reverse error rates
errR <- learnErrors(filtRs)

# Sample inference and merger of paired-end reads
mergers <- vector("list", length(sample.names))
names(mergers) <- sample.names
for(sam in sample.names) {
  cat("Processing:", sam, "\n")
  derepF <- derepFastq(filtFs[[sam]])
  ddF <- dada(derepF, err=errF, multithread=TRUE)
  derepR <- derepFastq(filtRs[[sam]])
  ddR <- dada(derepR, err=errR, multithread=TRUE)
  merger <- mergePairs(ddF, derepF, ddR, derepR)
  mergers[[sam]] <- merger
}
rm(derepF); rm(derepR)

# Construct sequence table and remove chimeras
seqtab_run2 <- makeSequenceTable(mergers)
saveRDS(seqtab, "/Users/whitneyware/IER_Sleeve/IER_combined/mergedFwdRev/IER_run_2_seqtab.rds")

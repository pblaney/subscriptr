# SUBSCRiPTR
A collection of SLURM batch submission and accessory scripts for BigPurple - NYU Langone Health HPC

## Usage
Each script includes a help message that can be displayed the same for all: `./script.sh -h`

| Script | Quick Description |
| --- | --- |
| `bamMerger.sh` | merge all BAMs within a directory |
| `cramConverter.sh` | convert all CRAMs within a directory into BAMs |
| `egaDataDownloader.sh` | download EGA data into a subdirectory |
| `fileRenamer.sh` | rename files within a directory based on file of names |
| `neatGenReads.sh` | simulate genomic reads to produce PE FASTQs and gold standard BAM/VCF |
| `sraFastqExtractor.sh` | dump the FASTQs from SRA data into a subdirectory |
| `sraFilePrefetcher.sh` | prefetch SRA data into a subdirectory |
| `tidyBam.sh` | tidy up BAM by removing any unmapped reads with non-zero MAPQ |
| `vcfSampleExtractor.sh` | extract all records in a VCF for a given sample |
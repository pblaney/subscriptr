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
| `sraFastqExtractor.sh` | dump the FASTQs from SRA data into a subdirectory |
| `sraFilePrefetcher.sh` | prefetch SRA data into a subdirectory |
| `tidyBam.sh` | tidy up BAM by removing any unmapped reads with non-zero MAPQ |


| DEPRECIATED|
| Script | Quick Description |
| --- | --- |
| `hintPre.sh` | perform the preprocessing step of HiNT pipeline |
| `hintCnv.sh` | perform the CNV calling step of HiNT pipeline |
| `hintTl.sh` | perform the translocation calling step of HiNT pipeline |
| `hintWorkflow.sh` | Wrapper script to run HiNT pipeline using SLURM |

#!/bin/bash

####################	Help Message	####################
Help()
{
	# Display help message
	echo 'DEPRECIATED - This tool has been incorporated into the hic-bench toolbox'
	echo 
	echo "This script will run the HiNT pipeline to call CNVs and translocations from Hi-C data"
	echo "Not a SLURM batch script"
	echo 
	echo "WARNING: This script expects the executible command 'hint' is on the user's PATH."
	echo "         Also, many of the required files are hardcoded paths"
	echo 
	echo "Usage:"
	echo '	/path/to/hintWorkflow.sh [fastqDir]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[fastqDir]	The user-provided path to directory of input FASTQs"
	echo 
	echo "Usage Example:"
	echo '	~/subscriptr/hintWorkflow.sh /gpfs/scratch/username/hintAnalysis/inputFastqs/'
	echo 
}

while getopts ":h" option;
	do
		case $option in
			h) # Show help message
				Help
				exit;;
		    \?) # Reject other passed options
				echo "Invalid option"
				exit;;
		esac
	done

############################################################

# Debugging settings
set -euo pipefail

echo "###############################################################"
echo "#                       HiNT Workflow                         #"
echo "#                  PRE  -->  CNV  -->  TL                     #"
echo "###############################################################"
echo 

# Load required modules
module add r/3.6.1

# List modules for quick debugging
module list -t
echo 

# User defined directory containing all Hi-C FASTQ files
fastqDir=${1}

# Extract the sample name from the directory path
sample=$(echo "${fastqDir}" | sed -e 's,[a-zA-Z]*/$,,' -e 's,/$,,' -e 's,/.*/,,' -e 's,_,-,')

# Set path to pipeline main directory and output directory
pipelineDir="/gpfs/scratch/blanep01/hicAnalysis/hintPipeline"
outputDir="${pipelineDir}/output"
mkdir -p "${outputDir}"

# Set variables to hold paths to reference files and tools
refGenome="${pipelineDir}/bwaIndex/hg38/hg38.fa"
refData="${pipelineDir}/references/hg38"
backgroundDir="${pipelineDir}/backgroundMatrices/hg38"
pairtools="/gpfs/scratch/blanep01/hicAnalysis/bin/pairtools"
samtools="/gpfs/scratch/blanep01/hicAnalysis/bin/samtools"
juicer="/gpfs/scratch/blanep01/hicAnalysis/bin/juicer_tools.1.8.9_jcuda.0.8.jar"
bwa="/gpfs/scratch/blanep01/hicAnalysis/bin/bwa"
bicSeq="/gpfs/scratch/blanep01/hicAnalysis/bin/BICseq2-seg_v0.7.3"
pairix="/gpfs/scratch/blanep01/hicAnalysis/bin/pairix"

# Create subdirectory in output folder for all files for sample run
sampleOutputDir="${outputDir}/${sample}"
mkdir -p "${sampleOutputDir}"

# Merge all sample Hi-C FASTQs in given directory
fastqR1="${sampleOutputDir}/${sample}_merged_R1.fastq.gz"
fastqR2="${sampleOutputDir}/${sample}_merged_R2.fastq.gz"
cat "${fastqDir}"*"R1"*."fastq.gz" > "${fastqR1}"
cat "${fastqDir}"*"R2"*".fastq.gz" > "${fastqR2}"

# Set the HiNT-PRE call command
hintPreCall="
sbatch \
--job-name=${sample} \
--parsable \
~/hintPre.sh \
${fastqR1} \
${fastqR2} \
${sample} \
${sampleOutputDir} \
${refGenome} \
${refData} \
${pairtools} \
${samtools} \
${juicer} \
${bwa}"

# Submit the HiNT-PRE call as a batch job and capture the job ID for downstream dependency
hintPreJobId=$(eval "${hintPreCall}")

# Set the Sambamba Flagstat call command
sambambaFlagstatCall="
sbatch \
--job-name=${sample} \
--dependency=afterok:${hintPreJobId} \
~/sambambaFlagstat.sh \
${sample} \
${sampleOutputDir} \
${fastqR1} \
${fastqR2}"

# Submit the Sambamba Flagstat call as a batch job to execute dependent on the HiNT-PRE call successfully executing
eval "${sambambaFlagstatCall}"

# Set variable for the output 10kb contact matrix from HiNT-PRE to use as input for HiNT-CNV
contactMatrix10kb="${sampleOutputDir}/${sample}.hic"

# Set the HiNT-CNV call command
hintCnvCall="
sbatch \
--job-name=${sample} \
--dependency=afterok:${hintPreJobId} \
~/hintCnv.sh \
${sample} \
${sampleOutputDir} \
${contactMatrix10kb} \
${refData} \
${bicSeq}"

# Submit the HiNT-CNV call as a batch job to execute dependent on the HiNT-PRE call successfully executing
eval "${hintCnvCall}"

# Set variables for the chimeric reads from HiNT-PRE to use as input for HiNT-TL
chimericReads="${sampleOutputDir}/${sample}_chimeric.sorted.pairsam.gz"

# Set the HiNT-TL call command
hintTlCall="
sbatch \
--job-name=${sample} \
--dependency=afterok:${hintPreJobId} \
~/hintTl.sh \
${sample} \
${sampleOutputDir} \
${contactMatrix10kb} \
${chimericReads} \
${refData} \
${backgroundDir} \
${pairix}"

# Submit the HiNT-CL call as a batch job to execute dependent on the HiNT-PRE call successfully executing
eval "${hintTlCall}"

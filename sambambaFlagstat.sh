#!/bin/bash

#SBATCH --partition=cpu_dev
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=04:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=sambambaFlagstat-%x.log

# Debugging settings
set -euo pipefail

echo "###############################################################"
echo "#                     Sambamba Flagstat                       #"
echo "###############################################################"
echo 

# Load required module
module add sambamba/0.6.8

# List modules for quick debugging
module list -t
echo 

# User defined BAM file, and R1/R2 FASTQ files as input
sample=${1}
sampleOutputDir=${2}
fastqR1=${3}
fastqR2=${4}

echo "BAM ANALYZED: ${sampleOutputDir}/${sample}.bam"
echo 

# Run flagstat to generate alignment statistics
flagstatFile="${sampleOutputDir}/${sample}.flagstat.txt"
sambambaCall="sambamba-0.6.8 flagstat ${sampleOutputDir}/${sample}.bam > ${flagstatFile}"
eval "$sambambaCall"
sleep 5

# Check if flagstat file was generated
if [ ! -s "${flagstatFile}" ] ; then
	echo 
	echo "ERROR: ${flagstatFile} NOT GENERATED"
	echo "###############################################################"
	echo 
fi

# Get number of input reads
fastqLines=$(zcat "${fastqR1}" | wc -l)
inputReads=$(echo "${fastqLines} / 2" | bc)

# Include secondary alignments in calculation of mapped and total
allMappedReads=$(cat "${flagstatFile}" | grep -m 1 "mapped (" | cut -d ' ' -f 1)
secMappedReads=$(cat "${flagstatFile}" | grep -m 1 "secondary" | cut -d ' ' -f 1)
mappedReads=$(echo "${allMappedReads} - ${secMappedReads}" | bc)

pctMappedReads=$(echo "(${mappedReads} / ${inputReads}) * 100" | bc -l | cut -c 1-4)
pctMappedReads="${pctMappedReads}%"

chimericReads=$(cat "${flagstatFile}" | grep -m 1 "mate mapped to different chr" | cut -d ' ' -f 1)

pctChimericReads=$(echo "(${chimericReads} / ${mappedReads}) * 100" | bc -l | cut -c 1-4)
pctChimericReads="${pctChimericReads}%"

# Add header to alignment summary file
alignmentSummary="${sampleOutputDir}/${sample}.alignmentSummary.csv"
echo "SAMPLE,INPUT READS,MAPPED READS (MQ10),MAPPED %,CHIMERIC %" > "${alignmentSummary}"

# Add values to alignment summary file
echo "${sample},${inputReads},${mappedReads},${pctMappedReads},${pctChimericReads}" >> "${alignmentSummary}"

if [ -s "${alignmentSummary}" ] ; then

	rm "${fastqR1}"
	rm "${fastqR2}"

	echo 
	echo "ALIGNMENT SUMMARY: ${alignmentSummary}"
	echo "###############################################################"
	echo 
fi

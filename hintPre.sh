#!/bin/bash

#SBATCH --partition=cpu_short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=4G
#SBATCH --time=12:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=hintPRE-%x.log

# Debugging settings
set -euo pipefail

echo "###############################################################"
echo "#                          HiNT-PRE                           #"
echo "###############################################################"
echo 

# List modules for quick debugging
module list -t
echo 

# Set variables to hold paths to reference files and tools provided in batch call
inputData=${1}
sample=${2}
sampleOutputDir=${3}
refData=${4}
pairtools=${5}
samtools=${6}
juicer=${7}

echo "SAMPLE RUN: $sample"
echo "OUTPUT DIRECTORY: $sampleOutputDir"
echo "REFERENCE GENOME: hg38"
echo "HI-C MATRIX RESOLUTION: 50kb"
echo 

# HiNT-PRE call using BAM
hint pre \
-d "${inputData}" \
--refdir "${refData}" \
--informat bam \
--outformat juicer \
-g hg38 \
-n "${sample}" \
-r 50 \
-o "${sampleOutputDir}" \
--pairtoolspath "${pairtools}" \
--samtoolspath "${samtools}" \
--juicerpath "${juicer}"

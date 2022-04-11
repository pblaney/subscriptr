#!/bin/bash

#SBATCH --partition=cpu_short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2G
#SBATCH --time=12:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=hintCNV-%x.log

# Debugging settings
set -euo pipefail

echo "###############################################################"
echo "#                          HiNT-CNV                           #"
echo "###############################################################"
echo 

# List modules for quick debugging
module list -t
echo 

# Set variables to hold paths to reference files and tools provided in batch call
sample=${1}
sampleOutputDir=${2}
contactMatrix=${3}
refData=${4}
resolution=${5}
bicSeq=${6}
enzyme=${7}

echo "MATRIX ANALYZED: $contactMatrix"
echo "RESOLUTION: $resolution"
echo "RESTRICTION ENZYME: $enzyme"
echo 

# HiNT-CNV call using juicer output
hint cnv \
-m "${contactMatrix}" \
-f juicer \
--refdir "${refData}" \
-r "${resolution}" \
-g hg38 \
-n "${sample}" \
-o "${sampleOutputDir}" \
--bicseq "${bicSeq}" \
-e "${enzyme}"

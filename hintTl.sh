#!/bin/bash

#SBATCH --partition=fn_long
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=10G
#SBATCH --time=28-00:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=hintTL-%x.log

# Debugging settings
set -euo pipefail

echo "###############################################################"
echo "#                          HiNT-TL                            #"
echo "###############################################################"
echo 

# List modules for quick debugging
module list -t
echo 

# Set variables to hold paths to reference files and tools provided in batch call
sample=${1}
sampleOutputDir=${2}
contactMatrix10kb=${3}
chimericReads=${4}
refData=${5}
backgroundDir=${6}
pairix=${7}

echo "MATRICES USED: $contactMatrix10kb"
echo "CHIMERIC READS USED: $chimericReads"
echo 

# HiNT-TL call using juicer output and chimeric reads
hint tl \
-m "${contactMatrix10kb}" \
-f juicer \
--chimeric "${chimericReads}" \
--refdir "${refData}" \
--backdir "${backgroundDir}" \
-g hg38 \
-e DpnII \
-n "${sample}" \
--ppath "${pairix}" \
-o "${sampleOutputDir}"

echo 
echo "###############################################################"
echo 

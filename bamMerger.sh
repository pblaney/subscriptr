#!/bin/bash

#SBATCH --partition=cpu_medium
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=6G
#SBATCH --time=24:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=patrick.blaney@nyulangone.org
#SBATCH --output=bamMerger-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will merge all BAMs within a user-defined directory and"
	echo "produce a merged BAM with a user-defined name"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] /path/to/bamMerger.sh [bamDir] [mergedBam]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[jobName]	The name of the SLURM job, must be unique"
	echo "	[bamDir]	The user-defined directory that contains all input BAM files to be merged"
	echo "	[mergedBam]	The name of the output merged BAM"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test ~/subscriptr/bamMerger.sh /gpfs/scratch/username/splitBams/ test.merged.bam'
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

echo "###########################################################"
echo "#                        BAM Merger                       #"
echo "###########################################################"
echo 

# Load Sambamba/SAMtools modules
module add samtools/1.16

# List modules for quick debugging
module list -t
echo 

# Set variables to hold user defined directory that contains all input BAM files and
# name of output merged BAM
bamDir=$1
mergedBam=$2

# Set variable to hold the list of input BAMs to go into the command
bamList=$(ls -1 "${bamDir}"*".bam" | tr '\n' ' ')

# Issue the Sambamba merge command
cmd="
samtools merge -o - --threads 7 ${bamList} | samtools sort --threads 7 -m 4G -o ${mergedBam}
"
echo "CMD: ${cmd}"
eval "${cmd}"

# Run sanity check on converted BAM file
echo 
echo "Running sanity check on ${mergedBam}...."

# SAMtools command for the sanity check
samtools quickcheck "${mergedBam}" && echo "PASSED" \
	|| echo "FAILED"

echo "###########################################################"
echo 

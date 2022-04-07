#!/bin/bash

#SBATCH --partition=cpu_medium
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=4G
#SBATCH --time=3-00:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=patrick.blaney@nyulangone.org
#SBATCH --output=bamMerger-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will tidy up a user-provided BAM by removing any unmapped reads with non-zero MAPQ"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] /path/to/tidyBam.sh [inputBam]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[jobName]	The name of the SLURM job, must be unique"
	echo "	[inputBam]	The user-provided BAM to tidy"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test ~/subscriptr/tidyBam.sh test.bam'
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
echo "#              Tidy Up Unmapped Reads in BAM              #"
echo "###########################################################"
echo 

# Load SAMtools modules
module add samtools/1.10

# List modules for quick debugging
module list -t
echo 

# Set variable to hold user defined input BAM file
inputBam=$1

# Derive output BAM name based on input BAM file
outputBam=$(echo "${inputBam}" | sed -E 's|.bam$|.tidy.bam|')

# Issue SAMtools command to filter out unmapped reads for BAM's use in downstream processes
cmd="
samtools view -bF 4 ${inputBam} > ${outputBam}
"

echo "CMD: ${cmd}"
eval "${cmd}"

# SAMtools command for the sanity check
samtools quickcheck "${outputBam}" && echo "PASSED" \
	|| echo "FAILED"

echo "###########################################################"
echo 

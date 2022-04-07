#!/bin/bash

#SBATCH --partition=cpu_medium
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=9
#SBATCH --mem-per-cpu=2G
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,FAIL,END
#SBATCH --mail-user=patrick.blaney@nyulangone.org
#SBATCH --output=cramConverter-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will convert all CRAMs within a user-defined directory into BAMs with hg38 as reference and"
	echo "output these BAMs into a subdirectory"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] /path/to/cramConverter.sh [cramDir]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[jobName]	The name of the SLURM job, must be unique"
	echo "	[cramDir]	The user-defined directory that contains all input CRAM files to be converted"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test ~/subscriptr/cramConverter.sh /gpfs/scratch/usernam/crams/'
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
echo "#                  CRAM to BAM Converter                  #"
echo "###########################################################"
echo 

# Load SAMtools module
module add samtools/1.10

# List modules for quick debugging
module list -t
echo 

# Set variables to hold user-defined directory that contains all input CRAM files,
# subdirectory to place converted BAMs, and path to reference genome FASTA
cramDir=$1
convertedBamsDir="${cramDir}convertedBams"
refGenome="/gpfs/data/morganlab/referenceFiles/hg38/Homo_sapiens_assembly38.fasta"

# Create the converted BAMs directory if it doesn't already exist
mkdir -p "${convertedBamsDir}"

# Create a function that converts CRAM file to BAM file, then checks the output BAM for 
# correctness
cramConverter() {
	for cramFile in "${cramDir}"*".cram"
	do
		# Isolate sample name from filename
		sample=$(echo "$cramFile" | sed -e 's,.cram,,' -e 's,/.*/,,')

		# Execution statement for more easily understood report
		echo 
		echo "Beginning conversion of ${cramFile}...."
		echo 

		# Issue the samtools view command
		cmd="
		samtools view \
		-b \
		--threads 5 \
		--reference ${refGenome} \
		${cramFile} > '${convertedBamsDir}/${sample}.bam'
		"
		echo "CMD: ${cmd}"
		eval "${cmd}"

		# Run sanity check on converted BAM file
		echo 
		echo "Running sanity check on ${sample}.bam ...."

		# SAMtools command for the sanity check
		samtools quickcheck "${convertedBamsDir}/${sample}.bam" && echo "PASSED" \
			|| echo "FAILED"

		echo "###########################################################"

	done
}

# Call the function
cramConverter

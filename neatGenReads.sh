#!/bin/bash

#SBATCH --partition=cpu_long
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=18G
#SBATCH --time=10-00:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=neatGenReads-%x.log

####################	Help Message	####################
Help()
{
	# Display help message
	echo "This script will run NEAT genReads to simulate genomic reads and produce PE FASTQs and gold standard BAM/VCF"
	echo "based on a user-provided VCF of desired known SNVs/InDels"
	echo 
	echo "WARNING: This script expects a Singularity container for NEAT and reference genome files within the launch directory"
	echo 
	echo "Usage:"
	echo '	sbatch --job-name=[jobName] --mail-user=[email] /path/to/neatGenReads.sh [sampleVcf]'
	echo 
	echo "Argument Descriptions:"
	echo "	[-h]		Print this message"
	echo "	[jobName]	The name of the SLURM job, must be unique"
	echo "	[email]		The user's email address to receive notifications"
	echo "	[sampleVcf]	The user-provided sample VCF they wish to use as the known SNVs/InDels"
	echo 
	echo "Usage Example:"
	echo '	sbatch --job-name=test --mail-user=example@nyulangone.org ~/subscriptr/neatGenReads.sh /gpfs/scratch/username/input.vcf'
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
echo "#                      NEAT genReads                      #"
echo "###########################################################"
echo 

# Load BCFtools module
module add singularity/3.7.1

# List modules for quick debugging
module list -t
echo 

# Set variable for user-defined sample name to extract, and the input VCF
sampleVcf=$1

# Issue the Singularity command
sampleName=$(echo ${sampleVcf} | sed 's|.vcf||')

cmd="
singularity exec -B \${PWD}:/home/toolshed/data --pwd /home/toolshed/data neat-3.0.simg \
python /home/toolshed/neat-genreads-3.0/gen_reads.py \
-r Homo_sapiens_assembly38.canonical.fasta \
-R 151 \
-o ${sampleName} \
-c 30 \
-v ${sampleVcf} \
--pe 300 30 \
--bam \
--vcf \
"

echo "CMD: ${cmd}"
eval "${cmd}"

echo 
echo "###########################################################"
echo 

#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 6:00:00
#SBATCH -p newnodes
#SBATCH -J trim
#SBATCH --mem=10G
#SBATCH --error=trim_%J.err
#SBATCH --mail-user=ddumit@mit.edu

id=$1

DATA_DIR="$HOME/corals2/${id}*" # edit
OUT_DIR="$HOME/corals2/trimmed_files" # edit

mkdir -p $OUT_DIR

threads=${2:-1}

fwd=$( ls $DATA_DIR/*${id}*1_sequence.fastq ) # edit
rev=$( ls $DATA_DIR/*${id}*2_sequence.fastq ) # edit

# Default trim settings
java -jar /cm/shared/engaging/Trimmomatic/Trimmomatic-0.36/trimmomatic-0.36.jar PE \
  -threads $threads $fwd $rev \
  $OUT_DIR/${id}_1_paired.fastq.gz \
  $OUT_DIR/${id}_1_single.fastq.gz \
  $OUT_DIR/${id}_2_paired.fastq.gz \
  $OUT_DIR/${id}_2_single.fastq.gz \
  ILLUMINACLIP:/home/ddumit/trimmomatic/adapters/TruSeq3-PE-2.fa:2:20:10 \
  LEADING:3 \
  TRAILING:3 \
  SLIDINGWINDOW:10:20 \
  MINLEN:36


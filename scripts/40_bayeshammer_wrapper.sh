#!/bin/bash

SCR_DIR="$HOME/scripts" # edit - for you, probably SCR_DIR="$HOME/scripts"

cat >$SCR_DIR/bayeshammer.sh<<"EOF"
#!/bin/bash
#SBATCH -N 1
#SBATCH -n 4
#SBATCH -t 12:00:00
#SBATCH -p newnodes
#SBATCH -J bayeshammer
#SBATCH --mem=20G
#SBATCH -o bayeshammer_%j.out
#SBATCH -e bayeshammer_%j.err

id=$1

DATA_DIR="$HOME/corals2/trimmed_files" # edit - for you, I think this should be DATA_DIR="$HOME/corals2/trimmed_files"

OUT_DIR="$HOME/corals2/BH_files/${id}"
# make sure that OUT_DIR includes the variable $id in it - e.g. OUT_DIR="$HOME/corals2/BH_files/${id}"
# you also need to include whether you're running the paired reads or which of the single reads [you'll see what I mean below these comments]
# the corrected reads will be stored in a directory created by bayeshammer called "corrected"
# so if you don't include something unique in the OUT_DIR path for each time you call the spades.py script, every single call will overwrite the previous one since $OUT_DIR would be the same for all calls of the script
# therefore, after bayeshammer has finished running, you will find the output files you want to use for the megahit step in each of the "corrected" directories (three per $id)
# those output files will be named according to the format ${id}_<1/2>_<paired/single>.fastq.00.0_0.cor.fastq.gz (with a 5th file too, labeled "unpaired")

mkdir -p $OUT_DIR/paired
mkdir -p $OUT_DIR/single1
mkdir -p $OUT_DIR/single2

/home/gaberoo/.linuxbrew/bin/spades.py --only-error-correction -1 $DATA_DIR/${id}_1_paired.fastq.gz -2 $DATA_DIR/${id}_2_paired.fastq.gz -t 4 -m 20 --phred-offset 33 -o $OUT_DIR/paired
/home/gaberoo/.linuxbrew/bin/spades.py --only-error-correction -s $DATA_DIR/${id}_1_single.fastq.gz -t 4 -m 20 --phred-offset 33 -o $OUT_DIR/single1
/home/gaberoo/.linuxbrew/bin/spades.py --only-error-correction -s $DATA_DIR/${id}_2_single.fastq.gz -t 4 -m 20 --phred-offset 33 -o $OUT_DIR/single2

EOF

for id in `cat $SCR_DIR/sample_ids.txt` # edit
do
	sbatch $SCR_DIR/bayeshammer.sh $id
done

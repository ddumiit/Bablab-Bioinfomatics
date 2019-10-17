#!/bin/bash

SCR_DIR="$HOME/scripts" # edit - for you, probably SCR_DIR="$HOME/scripts"

cat >$SCR_DIR/megahit_maxbin_checkm.sh<<"EOF"
#!/bin/bash
#SBATCH -N 1
#SBATCH --constraint=centos6 
#SBATCH -n 2
#SBATCH -J megahit_maxbin_checkm
#SBATCH -p newnodes
#SBATCH -t 2:00:00
#SBATCH --mem=80G
#SBATCH -o megahit_maxbin_checkm_%j.out
#SBATCH -e megahit_maxbin_checkm_%j.err

id=$1

# assembly

BH_DIR="$HOME/corals2/BH_files/${id}" # edit - for you, probably BH_DIR="$HOME/corals2/BH_files/${id}""
ASS_DIR="$HOME/corals2/ASS_DIR/${id}" # edit; recommend creating one directory per assembly (i.e. per $id) because many files will be made, so use variables in the directory name
rm -r $ASS_DIR # because megahit will not run if ASS_DIR already exists

/home/gaberoo/.linuxbrew/bin/megahit -t 2 \
	-1 $BH_DIR/paired/corrected/${id}_1_paired.fastq.00.0_0.cor.fastq.gz \
	-2 $BH_DIR/paired/corrected/${id}_2_paired.fastq.00.0_0.cor.fastq.gz \
	-r $BH_DIR/single1/corrected/${id}_1_single.fastq.00.0_0.cor.fastq.gz \
	-r $BH_DIR/single2/corrected/${id}_2_single.fastq.00.0_0.cor.fastq.gz \
	-r $BH_DIR/paired/corrected/${id}__unpaired.00.0_0.cor.fastq.gz \
	-o $ASS_DIR

mkdir -p $ASS_DIR/fastg
for p in `echo {21,29,39,59,79,99,119,141}` # these are the various k-mer lengths tried (set by the default parameters of megahit)
	do /home/gaberoo/.linuxbrew/bin/megahit_toolkit contig2fastg $p \
	$ASS_DIR/intermediate_contigs/k${p}.contigs.fa > $ASS_DIR/fastg/k${p}.fastg
done
zip $ASS_DIR/fastg/${id}.zip $ASS_DIR/fastg/*.fastg # these fastg files contain the actual information about how reads were assembled - we can visualize these files as graphs with the program Bandage in person

# binning

module load gcc/4.8.4
mkdir -p $ASS_DIR/maxbin
/home/ddumit/Software/MaxBin-2.2.7/run_MaxBin.pl -thread 2 -contig $ASS_DIR/final.contigs.fa \
	-reads1 $BH_DIR/paired/corrected/${id}_1_paired.fastq.00.0_0.cor.fastq.gz \
	-reads2 $BH_DIR/paired/corrected/${id}_2_paired.fastq.00.0_0.cor.fastq.gz \
	-reads3 $BH_DIR/single1/corrected/${id}_1_single.fastq.00.0_0.cor.fastq.gz \
	-reads4 $BH_DIR/single2/corrected/${id}_2_single.fastq.00.0_0.cor.fastq.gz \
	-reads5 $BH_DIR/paired/corrected/${id}__unpaired.00.0_0.cor.fastq.gz \
	-out $ASS_DIR/maxbin/bins


# quality check and taxonomic assignment

conda activate py27
mkdir -p $ASS_DIR/maxbin/checkm
checkm lineage_wf -x fasta $ASS_DIR/maxbin $ASS_DIR/maxbin/checkm
checkm qa $ASS_DIR/maxbin/checkm/lineage.ms $ASS_DIR/maxbin/checkm > $ASS_DIR/maxbin/checkm/summary.txt
checkm tree_qa $ASS_DIR/maxbin/checkm > $ASS_DIR/maxbin/checkm/phylo_summary.txt


EOF

for id in `cat $SCR_DIR/sample_ids.txt` # edit
do
	sbatch $SCR_DIR/megahit_maxbin_checkm.sh $id
done

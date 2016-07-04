# Directories
SRCDIR = $(CURDIR)/src
FSMDIR = ~/software/bin/
SEERDIR = ~/software/seer/
MASHDIR = ~/software/bin/
INDEXESDIR = ../indexes
GFFDIR = ../gff
GFFEXT = gff
# Output directories
MASHOUTDIR = $(CURDIR)/mash
POSMAPDIR = $(CURDIR)/positive_mappings
NEGMAPDIR = $(CURDIR)/negative_mappings

$(MASHOUTDIR):
	mkdir -p $@
$(POSMAPDIR):
	mkdir -p $@
$(NEGMAPDIR):
	mkdir -p $@

# Parameters
# fsm-lite
FSMMIN = 9
FSMMAX = 100
FSMMINFREQ = 1
FSMMINFILES = 2
# seer
THREADS = 1
MAF = 0.05

# Input files
INPUT = input.txt
PHENOTYPES = phenotypes.txt

# Scripts to download
SEERSCRIPT = $(SRCDIR)/R_mds.pl

$(SEERSCRIPT):
	wget -O $@ https://raw.githubusercontent.com/johnlees/seer/master/scripts/R_mds.pl

# Output files
FSMTMP = tmp.txt
KMERS = kmers.gz
DISTANCE = distances.csv
PROJECTION = projection
PROJECTIONOUT = $(PROJECTION).samples
ALLKMERS = all.kmers
FILTEREDKMERS = filtered.kmers
POSFASTQ = positive_kmers.fastq
NEGFASTQ = negative_kmers.fastq
POSMAPPINGDONE = positive_mapping.done
NEGMAPPINGDONE = negative_mapping.done

####################
# Kmers generation #
####################

$(KMERS): $(INPUT)
	$(FSMDIR)fsm-lite -l $< -t $(FSMTMP) -m $(FSMMIN) -M $(FSMMAX) -f $(FSMMINFREQ) -s $(FSMMINFILES) -v | gzip > $@

#######################
# Distance estimation #
#######################

$(DISTANCE): $(MASHOUTDIR) $(INPUT)
	for infile in $$(awk '{print $$2}' $(INPUT)); \
	do \
	  $(MASHDIR)mash sketch $$infile -o $(MASHOUTDIR)/$$(basename $$infile .fasta | awk -F '_' '{print $$1}'); \
	done
	for sketch in $$(find $(MASHOUTDIR) -type f -name '*.msh');\
	do \
	  $(MASHDIR)mash dist $$sketch $(MASHOUTDIR)/*.msh > $(MASHOUTDIR)/$$(basename $$sketch .msh).dist; \
	done
	cat $(MASHOUTDIR)/*.dist | $(SRCDIR)/mash2mat > $@

##############
# Projection #
##############

$(PROJECTIONOUT): $(DISTANCE) $(PHENOTYPES) $(SEERSCRIPT)
	perl $(SEERSCRIPT) -d $(DISTANCE) -p $(PHENOTYPES) -o $(PROJECTION)

########
# Seer #
########

$(ALLKMERS): $(KMERS) $(PROJECTIONOUT) $(PHENOTYPES)
	-$(SEERDIR)seer -k $(KMERS) --pheno $(PHENOTYPES) --struct $(PROJECTION) --threads $(THREADS) --print_samples > $@

$(FILTEREDKMERS): $(ALLKMERS)
	$(SEERDIR)filter_seer -k $< --maf $(MAF) --sort pval > $@

###########
# Mapping #
###########

$(POSFASTQ):
	$(SRCDIR)/kmers2fastq $(FILTEREDKMERS) --beta positive > $@
$(NEGFASTQ):
	$(SRCDIR)/kmers2fastq $(FILTEREDKMERS) --beta negative > $@

$(POSMAPPINGDONE): $(POSMAPDIR) $(POSFASTQ)
	for sample in $$(awk '{print $$1}' $(INPUT)); \
	do \
	  bowtie2 -q -U $(POSFASTQ) --ignore-quals -D 24 -R 3 -N 0 -L 7 -i S,1,0.50 -x $(INDEXESDIR)/$$sample > $(POSMAPDIR)/$$sample".sam"; \
	  samtools view -bS $(POSMAPDIR)/$$sample".sam" -o $(POSMAPDIR)/$$sample".bam" && $(POSMAPDIR)/$$sample".sam"; \
	  bedtools intersect -a $(GFFDIR)/$$sample".$(GFFEXT)" -b $(POSMAPDIR)/$$sample".bam" > $(POSMAPDIR)/$$sample && rm $(POSMAPDIR)/$$sample".bam"; \
	done
	touch $@

$(NEGMAPPINGDONE): $(NEGMAPDIR) $(NEGFASTQ)
	for sample in $$(awk '{print $$1}' $(INPUT)); \
	do \
	  bowtie2 -q -U $(NEGFASTQ) --ignore-quals -D 24 -R 3 -N 0 -L 7 -i S,1,0.50 -x $(INDEXESDIR)/$$sample > $(NEGMAPDIR)/$$sample".sam"; \
	  samtools view -bS $(NEGMAPDIR)/$$sample".sam" -o $(NEGMAPDIR)/$$sample".bam" && $(NEGMAPDIR)/$$sample".sam"; \
	  bedtools intersect -a $(GFFDIR)/$$sample".$(GFFEXT)" -b $(NEGMAPDIR)/$$sample".bam" > $(NEGMAPDIR)/$$sample && rm $(NEGMAPDIR)/$$sample".bam"; \
	done
	touch $@

###########
# Targets #
###########

all: seer
seer: $(FILTEREDKMERS)
map: $(POSMAPPINGDONE) $(NEGMAPPINGDONE)

.PHONY: all seer map

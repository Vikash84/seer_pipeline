# Directories
SRCDIR = $(CURDIR)/src
FSMDIR = ~/software/bin/
SEERDIR = ~/software/seer/
MASHDIR = ~/software/bin/
MASHOUTDIR = $(CURDIR)/mash

$(MASHOUTDIR):
	mkdir -p $<

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
	-$(SEERDIR)filter_seer -k $< --maf $(MAF) --sort pval > $@

all: seer
seer: $(FILTEREDKMERS)

.PHONY: all seer

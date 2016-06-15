# Directories
SRCDIR = $(CURDIR)/src
FSMDIR = ~/software/bin/
SEERDIR = ~/software/seer/
MASHDIR = $(CURDIR)/mash

$(MASHDIR):
	mkdir -p $(MASHDIR)

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

# Output files
FSMTMP = tmp.txt
KMERS = kmers.gz
DISTANCE = distances.csv
PROJECTION = projection
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

$(DISTANCE): $(MASHDIR) $(INPUT)
	for infile in $$(awk '{print $$2}' $(INPUT)); \
	do \
	  mash sketch $$infile -o $(MASHDIR)/$$(basename $$infile .fasta | awk -F '_' '{print $$1}'); \
	done
	for sketch in $$(find $(MASHDIR) -type f -name '*.msh');\
	do \
	  mash dist $$sketch $(MASHDIR)/*.msh > $(MASHDIR)/$$(basename $$sketch .msh).dist; \
	done
	cat $(MASHDIR)/*.dist | $(SRCDIR)/mash2mat > $@

##############
# Projection #
##############

$(PROJECTION): $(DISTANCE) $(PHENOTYPES)
	perl $(SEERDIR)R_mds.pl -d $(DISTANCE) -p $(PHENOTYPES) -o $@

########
# Seer #
########

$(ALLKMERS): $(KMERS) $(PROJECTION) $(PHENOTYPES)
	$(SEERDIR)seer -k $(KMERS) --pheno $(PHENOTYPES) --struct $(PROJECTION) --threads $(THREADS) --print_samples > $@

$(FILTEREDKMERS): $(ALLKMERS)
	$(SEERDIR)filter_seer -k $< --maf $(MAF) --sort pval > $@

all: seer
seer: $(FILTEREDKMERS)

.PHONY: all seer

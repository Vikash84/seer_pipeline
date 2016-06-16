seer_pipeline
=============

**Run seer with no headaches**

SEER is a very interesting tool to run GWAS on bacterial datasets, but
running it (especially on older OSes) requires using many different tools.

This pipeline allows running SEER with one go, thus reducing unnecessary headaches.

Usage
-----

Place the two required input files (`input.txt` and `phenotypes.txt`) in
the same directory as the Makefile. The `input.txt` file is a tab-delimited
two-columns file in the format:

    SAMPLE /PATH/TO/FASTA

While the `phenotypes.txt` file is a tab-delimited three columns file in the format:

    SAMPLE SAMPLE PHENOTYPE

Once you have your files ready, simply type:

    make all

Prerequisites
-------------

* fsm-lite
* mash
* python (2.7+, 3.3+)
* pandas 
* perl
* R (3.2+)
* rhdf5
* seer

Copyright
---------

Copyright (C) <2016> EMBL-European Bioinformatics Institute

This program is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the   
GNU General Public License for more details.

Neither the institution name nor the name seer_pipeline
can be used to endorse or promote products derived from
this software without prior written permission.
For written permission, please contact <marco@ebi.ac.uk>.

Products derived from this software may not be called seer_pipeline
nor may seer_pipeline appear in their names without prior written
permission of the developers. You should have received a copy
of the GNU General Public License along with this program.
If not, see <http://www.gnu.org/licenses/>.

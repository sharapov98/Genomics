SELECT count(*) 
FROM persons;
SELECT count(*) 
FROM person_path;
--The person_path table has all possible paths through the network stored in persons, but only for those paths that end in the most recent generation. To check what the most recent generation is, do as follows:

SELECT max(generation) FROM persons; 
/*In the case of the onehundredbyonehundred database, the most recent generation is 100. 
Let's take a look at a few records for people in generation 1:*/

SELECT *
FROM persons 
WHERE generation = 1
LIMIT 20;
/*The WHERE constrains the set of selected records to some criteria, here the generation has to be 1. The LIMIT puts a limit on how many rows to display.  
List the men that have more than 3 children:*/

SELECT *
FROM persons
WHERE generation = 1
AND children > 3 
AND female IS FALSE;

SELECT persons_id, child_id 
FROM persons JOIN person_path ON (persons_id = ancestor_id) 
WHERE persons_id IN ( 120633, 120617, 120663 ) 
AND distance = 3;
/*Notice that we have now referenced two tables in the FROM clause: persons has been joined to person_path by mapping the persons_id field in persons to the ancestor_id field in person_path. And rather than make persons_id equal to a single integer, we allow it to match any of three integers. 
Suppose we want simply to count up the number of grandchildren for each persons_id. Do as follows, modifying it using your own set of persons_id:*/

SELECT persons_id AS "Grandparent", count(*) AS "Number of Grandchildren" 
FROM persons JOIN person_path ON (persons_id = ancestor_id) 
WHERE persons_id IN ( 120633, 120617, 120663 ) 
AND distance = 3
GROUP BY persons_id;

SELECT count(*) 
FROM persons p 
WHERE p.generation = 1 
AND EXISTS (SELECT 1 FROM person_path pp WHERE pp.ancestor_id = p.persons_id);
/*Two things to note: the "p" and "pp" are aliases following each table name and preceding each field name. Aliases are useful for keeping track of which table 
different field names are referencing. The other thing to noice is the use of a subquery: the EXISTS clause reports true if the query in the parentheses has found at 
least one record indicating that this persons_id in generation 1 has at least one descendant 100 generations later.  Do the results surprise you? 

Let's see how this changes over time by making the same calculation for each of the 100 generations. To do this I'm using three nested queries, where the 
outermost one serves as a loop to run through all 100 generations:*/

SELECT gen AS "generation", 
( SELECT count(*) 
  FROM persons p 
  WHERE p.generation = gen 
  AND EXISTS ( SELECT 1 FROM person_path pp WHERE pp.ancestor_id = p.persons_id )
) AS "ancestors"
FROM generate_series(1,100) gen;

SELECT persons_id, (
  SELECT count(*)
  FROM person_path pp 
  WHERE pp.ancestor_id = p.persons_id 
  AND pp.lineage = 'e' 
) AS "gggggGrandchildren"
FROM persons p
WHERE p.generation = 1
ORDER BY persons_id;

SELECT *
FROM people_path ppa,
     people_path ppb 
WHERE pp.child_id = A
AND ppb.child_id=B
AND ppa.lineage='f' AND ppb.lineage = 'f'
AND ppa.ancestor_id = ppb.ancestor_id

SELECT ppa.distance, ppa.ancestor_id 
FROM person_path ppa, person_path ppb 
WHERE ppa.ancestor_id = ppb.ancestor_id 
AND ppa.lineage = 'f' 
AND ppb.lineage = ppa.lineage 
GROUP BY ppa.ancestor_id, ppa.distance 
HAVING count(*) = ( 
   SELECT count(*) FROM persons 
   WHERE generation = (SELECT max(generation) FROM persons) 
) ^ 2
ORDER BY ppa.distance 
LIMIT 1;


SELECT dist AS "generation", count(*) AS "MRCAs"
FROM
   (  SELECT pa.persons_id, pb.persons_id, MIN(ppa.distance) AS dist
      FROM 
        person_path ppa,
        (SELECT persons_id  
        FROM persons 
        WHERE generation = (SELECT max(generation) FROM persons) 
        ORDER BY random() LIMIT 5) pa,
        person_path ppb,
        (SELECT persons_id  
        FROM persons 
        WHERE generation = (SELECT max(generation) FROM persons)
        ORDER BY random() LIMIT 5) pb 
      WHERE pa.persons_id > pb.persons_id 
      AND ppa.child_id = pa.persons_id 
      AND ppb.child_id = pb.persons_id 
      AND ppa.ancestor_id = ppb.ancestor_id 
      AND ppa.lineage = 'e' 
      AND ppb.lineage = 'e'
      GROUP BY pa.persons_id, pb.persons_id 
   ) minDist
GROUP BY dist 
ORDER BY dist;

SELECT count(*) base_pair, chromesome_id
FROM snps GROUP BY chromosome_id;

mkdir FREYUB
cd FREYUB

psql snppy

SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype 
FROM individuals i NATURAL JOIN groupings g 
WHERE i.family_id LIKE 'French' OR i.family_id LIKE 'Yoruba'
ORDER BY i.individuals_id 
LIMIT 58;
--This looks good, so now let's create the PED files. Let's try the following:

\copy (SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM individuals i NATURAL JOIN groupings g WHERE i.family_id LIKE 'French' OR i.family_id LIKE 'Yoruba' ORDER BY i.individuals_id LIMIT 58) TO 'FREYUB.ped' (FORMAT CSV, DELIMITER ' ');

\copy (SELECT i.family_id, i.individual_id, i.family_id FROM individuals i NATURAL JOIN groupings g WHERE i.family_id LIKE 'French' OR i.family_id LIKE 'Yoruba' ORDER BY i.individuals_id LIMIT 58 ) TO 'FREYUB.pop' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'HGDP' ORDER BY ds.seq_order ) TO 'FREYUB.map' (FORMAT CSV, DELIMITER ' '); 
--It's a little annoying that each \copy command has to be a single line, as this makes it harder to read or compose your queries. There is an alternative way of exporting to a text file using \o, but the downside is that it doesn't allow relative paths -- so I think it's best to use \copy. At any rate, you can now quit psql with \q and return to your shell.  The CSV format typically puts quotes around tokens that need to be escaped. Let's get rid of the quote using this Perl one-liner:

perl -i -pe's/"//g' FREYUB.ped
 

/*Optional: Transferring Genome Files to Your Personal Computer 
Some of you will prefer to run your analyses on your personal computer. This way you don't have to have a network connection and the software might run faster running natively than running on a virtual machine.  For those of you who would rather run your analyses on the remote VM, please skip this step. To transfer your data, I suggest archiving the FREYUB directory and using scp to do the transfer.
*/
cd
tar cvfz freyub.tar.gz FREYUB
exit
--This creates the compressed archive freyub.tar.gz in your home directory. You have disconnected from the remote shell with "exit," so you're now in the home directory of your PC. Transfer freyub.tar.gz (but change "team1" to whatever your login is) and decompress as follows:

scp team1@172.25.20.27:freyub.tar.gz ~/
tar -xzf freyub.tar.gz
You should now find the FREYUB directory in your home directory of your local PC. 

/* B: Converting PED Files to BED Files 
It's less efficient for PLINK to work with PED files, so we will convert them to binary files. Type ls to see a list of the files in your FREYUB directory -- you should see FREYUB.ped, FREYUB.map, and FREYUB.pop (recall that you can learn about the PED and MAP files here and here).  Do the conversion to binary as follows:
*/
plink --file FREYUB --make-bed -out FREYUB
head -n 20 FREYUB.fam

/*C: Cleansing the dataset of SNPs in LD 
Whether you're doing GAWAS analysis or just inferring population history, you often want to assume that each of your SNPs is accurately scored and each of your SNPs is segregating independently. Rare minor allele frequencies (commonly called MAFs) are more likely to be false scores in the genotyping process, and either way they're less informative about group relationships. Rare MAFs with frequencies less than 1% can be filtered out with the following switch: --maf 0.01.  In population genetics, the jargon term for alleles that segregate independently is known as linkage equilibrium, and therefore the opposite property is linkage disequilibrium or LD. A common parameter for measuring this is r2, where an r2 of 0 is when two neighboring alleles are in perfect equilibrium, while an r2 of 1 is when two neighboring alleles are perfectly linked and provide identical information among the populations under study. To identify and prune the genome of LD SNPs, we can use a "moving window" of 50,000 bases, a step length of 5,000, and an r2 cutoff of 0.2, like so: --indep-pairwise 50 5 0.2. Of course, if your purpose is to use LD blocks to find regions under strong selection, you would not want to filter out LD SNPs. Run the following command:
*/
plink --bfile FREYUB --maf 0.01 --indep-pairwise 50 5 0.2 --out FREYUB 

wc -l FREYUB.prune.in

D: Cleansing the dataset of closely related individuals 
While it seems exceedingly unlikely that broadly sampled genomes would happen on closely related individuals, duplicate entries and inclusion of data from studies that target particular families are still possible. Like with LD blocks, closely related individuals interfere with statistics for GWAS and population relatedness studies. One way of estimating relatedness is to use Identical by Descent (Links to an external site.) (IBD) mapping. We can calculate the proportion of IBD using the --genome switch (see for info here (Links to an external site.)). 

plink --bfile FREYUB --genome --extract FREYUB.prune.in --out FREYUB
Notice that we are using our prune.in file to exclude the SNPs we had filtered out in step C. You can use head FREYUB.genome to inspect the top of the file. As you can see, each individual is compared against every other individual and their relatedness is estimated under the PI_HAT column. 

E: Inspecting the Proportion of IBD in R 
If you are running PLINK locally on your Mac or PC, you can use R-Studio to graph results as you usually would. Note that you want to start by telling R-Studio what your working directory is. In Terminal, you can get your working directory using the pwd command and then in R-Studio type in:  setwd('/Users/my/working/directory/for/FREYUB/'). 

If you are running PLINK remotely on the VM, you may be able to use R running on the VM too. To do that, you have to allow X11 forwarding so that when graphics is displayed it gets pushed back to your computer. For this to work, connect to the VM in the following way:

ssh -X team1@172.25.20.27
Next, test whether X-windows is working by typing  xeyes. If it's working, you should see a little animated graphic appear on your screen. If it's not working, try the following: 

ibd <- read.table("FREYUB.genome", hea=T, as.is=T)
hist( ibd$PI_HAT, breaks = 100 )
You can better zoom in to the bar graph by limiting the y-axis: hist( ibd$PI_HAT, breaks = 100, ylim = c(0,300) ). As you can see, most individuals are unrelated, but there are a few with a relatedness close to 0.5 -- i.e. either siblings or parent-children.  We can exclude these individuals by picking out all those with a relatedness greater than 0.2 and saving them to a file called FREYUB.relatives.txt.

excluded = ibd[ ibd$PI_HAT > 0.2, c('FID2','IID2')]
write.table( excluded, file="FREYUB.relatives.txt", col.names = F, row.names = F, quote = F )
F: Create a Cleansed / Reduced Copy of the Data 
Now that we have a list of SNPs to exclude and relatives to exclude, we can filter these out and save a new binary file set that has been cleaned up:

plink --bfile FREYUB --extract FREYUB.prune.in --remove FREYUB.relatives.txt --make-bed -out FREYUB_clean
And you should now see a new set of FREYUB_clean files where the FREYUB_clean.bed takes up considerably less disk space than the original FREYUB.bed. 

G: Calculate Allele Frequencies 
One thing you might want to do with your data is calculate allele frequencies among these individuals. Run the following:

plink --bfile FREYUB_clean --freq --out FREYUB_clean
And use head to examine the top few lines in FREYUB_clean.frq. As you can see, each SNP is listed along with allele A1 and allele A2. The MAF column is giving you the frequency of allele A1. 

Recall that previously we had saved a query to a file called FREYUB.pop. This stored a list of individual_id and family_id values, which we can use to recalculate allele frequencies specific to each population:

plink --bfile FREYUB_clean --freq --within FREYUB.pop --out FREYUB_clean
This saves a "cluster-stratified" file called FREYUB_clean.frq.strat. Use head -n 40 to examine it, and see how the frequency of each SNPs is calculated separately for both the French and Yoruba populations. In most cases the allele frequencies are quite similar, but there may be some that differ noticeably.

H: Calculate Heterozygosity 
We might want to compare the amount of heterozygosity in the two populations, as this gives some sense of ancestral population size.  Run the following:

plink --bfile FREYUB_clean --het -out FREYUB_clean
And use head to examine the top few lines in FREYUB_clean.het. The column "O(HOM)" reports the number of homozygotes and the column "N(NM)" reports the number of scored SNPs.  We can use R to ingest the table and infer the proportion of heterozygous SNPs by subtracting the homozygotes from the total and dividing this by the total. We can do a box plot and a t-test to compare the differences between the populations. 

het <- read.table("FREYUB_clean.het", hea=T, as.is=T)
boxplot( ((N.NM. - O.HOM.)/O.HOM.) ~ FID,data=het, xlab="Pops", ylab="Heterozygotes")
t.test( ((N.NM. - O.HOM.)/O.HOM.) ~ FID, het)
I: Cluster the Genomes into Groups 
For this particular dataset, there's little doubt that the genetics of French and Yoruba people should cluster separately. Still, a significant proportion of the Yoruba live in Republic of Benin, which used to be a French colony, so there were opportunities for admixture both during colonial times and in contemporary France as a consequence of migration. Let's ask PLINK to group these genomes into two clusters by specifying the switch: --K 2 as follows:

plink --bfile FREYUB_clean --cluster --K 2 --out FREYUB_clean
And then inspect the results like so:

cat FREYUB_clean.cluster1


\copy (SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM individuals i NATURAL JOIN groupings g WHERE i.family_id LIKE 'French' OR i.family_id LIKE 'Yoruba' ORDER BY i.individuals_id ) TO 'FREYUB.ped' (FORMAT CSV, DELIMITER ' ');

\copy (SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'HGDP' ORDER BY ds.seq_order ) TO 'FREYUB.map' (FORMAT CSV, DELIMITER ' ');

\copy (SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM individuals i NATURAL JOIN groupings g WHERE i.family_id LIKE 'Yoruba' ORDER BY i.individuals_id ) TO 'YORUBA.ped' (FORMAT CSV, DELIMITER ' ');

\copy (SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'HGDP' ORDER BY ds.seq_order ) TO 'YORUBA.map' (FORMAT CSV, DELIMITER ' ');
perl -i -pe's/"//g' FREYUB.ped 
perl -i -pe's/"//g' YORUBA.ped

plink --file FREYUB --make-bed -out FREYUB
plink --file YORUBA --make-bed -out YORUBA
And now we can do Hardy-Weinberg calculations:

plink --bfile FREYUB --hardy --out FREYUB
plink --bfile YORUBA --hardy --out YORUBA
And we will only retain lines that have "ALL" in each line:

perl -i -ne 'print if /ALL/' FREYUB.hwe
perl -i -ne 'print if /ALL/' YORUBA.hwe

SELECT DISTINCT ON (rf.individual_id) rf.* 
FROM ( SELECT rank() OVER ( PARTITION BY family_id ORDER BY random() ), 
              g.group_name, i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype  
   FROM individuals i NATURAL JOIN groupings g 
   WHERE i.family_id NOT IN (SELECT family_id FROM groupings WHERE family_id LIKE 'African%' OR family_id LIKE '%Jews')
 ) rf 
WHERE rf.rank < 4;

\copy ( SELECT DISTINCT ON (rf.individual_id) rf.* FROM ( SELECT rank() OVER ( PARTITION BY family_id ORDER BY random() ), g.group_name, i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM individuals i NATURAL JOIN groupings g WHERE i.family_id NOT IN (SELECT family_id FROM groupings WHERE family_id LIKE 'African%' OR family_id LIKE '%Jews') ) rf WHERE rank < 4 ) TO 'MYDATA.txt' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'HGDP' ORDER BY ds.seq_order ) TO 'MYDATA.map' (FORMAT CSV, DELIMITER ' '); 

scp team7@172.25.20.27:MYDATA.q ~/

SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype 
FROM individuals i NATURAL JOIN groupings g 
WHERE g.group_name = 'Europe' 
AND i.family_id NOT IN ('Abkhazians', 'Adygei', 'Altaians', 'Armenians', 'AshkenazyJews', 'AzerbaijaniJews', 'Azeri', 'Balkar', 'Belorussian', 'Chechens', 'Dolgans', 'Evens', 'FrenchJews', 'Gagauz', 'Georgian', 'GeorgianJews', 'ItalianJews', 'Karelian', 'Komi', 'Kumyks', 'Lezgins', 'Lithuanians', 'Maris', 'Moldavian', 'Mordovians', 'Ossetian', 'Russian', 'Selkups', 'Tabassaran', 'Tatar', 'Turks', 'Udmurt', 'Ukranians', 'UtahWhite', 'Veps')
ORDER BY i.individuals_id;

\copy ( SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM individuals i NATURAL JOIN groupings g WHERE g.group_name = 'Europe' AND i.family_id NOT IN ('Abkhazians', 'Adygei', 'Altaians', 'Armenians', 'AshkenazyJews', 'AzerbaijaniJews', 'Azeri', 'Balkar', 'Belorussian', 'Chechens', 'Dolgans', 'Evens', 'FrenchJews', 'Gagauz', 'Georgian', 'GeorgianJews', 'ItalianJews', 'Karelian', 'Komi', 'Kumyks', 'Lezgins', 'Lithuanians', 'Maris', 'Moldavian', 'Mordovians', 'Ossetian', 'Russian', 'Selkups', 'Tabassaran', 'Tatar', 'Turks', 'Udmurt', 'Ukranians', 'UtahWhite', 'Veps') ORDER BY i.individuals_id ) TO 'EUROPE.ped' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'HGDP' ORDER BY ds.seq_order ) TO 'EUROPE.map' (FORMAT CSV, DELIMITER ' ');

scp ssh team7@172.25.20.27:~/MP/EU_EA_UNK_F_S.7.Q .\



perl -i -pe's/"//g' EUROPE.ped
plink --file EUROPE --make-bed -out EUROPE
plink --bfile EUROPE --pca 6  --out EUROPE

wget https://my.pgp-hms.org/user_file/download/2863 -O noel_genome.txt

wget https://piel-lab.com/courses/HI/Data/mystery_person.txt
plink --23file mystery_person.txt Unknown mp12345 i -9 0 0 --alleleACGT --make-bed -out UNK

SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype 
FROM individuals i NATURAL JOIN groupings g 
WHERE g.group_name = 'Europe' AND i.family_id <> 'UtahWhite' 
ORDER BY i.individuals_id;

\copy ( SELECT DISTINCT ON (rf.individual_id) rf.* FROM ( SELECT rank() OVER ( PARTITION BY family_id ORDER BY random() ), i.family_id, g.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM individuals i NATURAL JOIN groupings g WHERE g.family_id IN ('French', 'German', 'Han', 'Cambodians', 'Yoruba', 'Tajik', 'Tamil', 'Lebanese', 'AshkenazyJews') ORDER BY i.family_id, i.individual_id) rf WHERE rf.rank > 0 ) TO 'EU_EA.txt' (FORMAT CSV, DELIMITER ' ');
\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'HGDP' ORDER BY ds.seq_order ) TO 'EU_EA.map' (FORMAT CSV, DELIMITER ' '); 
perl -i -pe's/"//g' EU_EA.txt
perl -F"\s" -nlae'print join "\t", ($F[3], $F[2], $F[1])' EU_EA.txt > EU_EA.grp 
perl -F"\s" -nlae'print join "\t", @F[2..@F]' EU_EA.txt > EU_EA.ped

plink --file EU_EA --make-bed -out EU_EA

plink --bfile EU_EA --bmerge UNK.bed UNK.bim UNK.fam --make-bed --out EU_EA_UNK

plink --bfile UNK --flip EU_EA_UNK-merge.missnp --make-bed --out UNK_F
plink --bfile EU_EA --bmerge UNK_F.bed UNK_F.bim UNK_F.fam --make-bed --out EU_EA_UNK_F
plink --bfile EU_EA --write-snplist --out EU_EA

plink --bfile EU_EA_UNK_F --extract EU_EA.snplist --make-bed --out EU_EA_UNK_F_S

cp EU_EA.grp EU_EA_UNK_F_S.grp
echo -e 'mp12345 Unknown Unknown'>>EU_EA_UNK_F_S.grp

nohup time admixture -j12 EU_EA_UNK_F_S.bed 7 > admix.log 2>&1 &
echo $! > save_pid.txt



--KINSHIP exercise
SELECT individual_id || ',' || latitude || ',' || longitude || ',' || average_age::varchar AS "name,latitude,longitude,n"
FROM individuals JOIN datasets USING (datasets_id) 
WHERE family_id LIKE 'Pol%'
AND dataset_name = 'Reich_v37_2_AHO' 
AND average_age > 0 
ORDER BY average_age;

SELECT i.individual_id, average_age, 
  CASE WHEN i.sex='1' THEN 'male'
    WHEN i.sex='2' THEN 'female'
    ELSE 'other'
  END AS "Sex"
FROM individuals i JOIN datasets d USING (datasets_id) 
WHERE i.locality = 'Kierzkowo' AND d.dataset_name = 'Reich_v37_2_AHO' 
ORDER BY i.average_age;

\copy ( SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM individuals i JOIN datasets d USING (datasets_id) WHERE i.locality = 'Kierzkowo' AND d.dataset_name = 'Reich_v37_2_AHO' ORDER BY i.individuals_id ) TO 'POLES.ped' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT i.family_id, i.individual_id, i.family_id FROM individuals i JOIN datasets d USING (datasets_id) WHERE i.locality = 'Kierzkowo' AND d.dataset_name = 'Reich_v37_2_AHO' ORDER BY i.individuals_id ) TO 'POLES.pop' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'Reich_v37_2_AHO' ORDER BY ds.seq_order ) TO 'POLES.map' (FORMAT CSV, DELIMITER ' ');

perl -i -pe's/"//g' POLES.ped

plink --file POLES --make-bed -out POLES
plink --bfile POLES --genome --out POLES
cat POLES.genome
 --Four population test 
SELECT i.family_id, i.country, g.group_name, count(*) 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE d.dataset_name = 'Reich_v37_2_AHO' 
AND i.qc = 'PASS' 
AND i.average_age = 0 
AND (g.group_name = 'EastAsia' OR g.group_name = 'Oceania') 
GROUP BY g.group_name, i.country, i.family_id 
ORDER BY g.group_name, i.country, i.family_id;

SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE d.dataset_name = 'Reich_v37_2_AHO' AND i.qc = 'PASS' AND i.average_age = 0 
AND i.family_id IN ('Primate_Chimp', 'Yoruba', 'others...');

SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE d.dataset_name = 'Reich_v37_2_AHO' AND i.qc = 'PASS' AND i.average_age = 0 
AND i.family_id IN ('Primate_Chimp', 'Yoruba', 'others...');
UNION 
SELECT g.group_name AS "family_id", i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype  
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE d.dataset_name = 'Reich_v37_2_AHO' AND g.group_name = 'Denisovan' 
ORDER BY individual_id;

\copy ( SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE d.dataset_name = 'Reich_v37_2_AHO' AND i.qc = 'PASS' AND i.average_age = 0 AND i.family_id IN ('Malay', 'Uzbeks', 'Peruvian', 'Iranians', 'Estonians', 'Pathan','Egyptians', 'Primate_Chimp', 'Yoruba') UNION SELECT g.group_name AS "family_id", i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE d.dataset_name = 'Reich_v37_2_AHO' AND g.group_name = 'Denisovan' ORDER BY individual_id ) TO 'ASIA.ped' (FORMAT CSV, DELIMITER ' ');
\copy ( SELECT i.individual_id, 'U', i.family_id FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE d.dataset_name = 'Reich_v37_2_AHO' AND i.qc = 'PASS' AND i.average_age = 0 AND i.family_id IN ('Malay', 'Uzbeks', 'Peruvian', 'Iranians', 'Estonians', 'Pathan','Egyptians', 'Primate_Chimp', 'Yoruba') UNION SELECT i.individual_id, 'U', g.group_name AS "family_id" FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE d.dataset_name = 'Reich_v37_2_AHO' AND g.group_name = 'Denisovan' ORDER BY individual_id ) TO 'ASIA.pop' (FORMAT CSV, DELIMITER ' ');
\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'Reich_v37_2_AHO' ORDER BY ds.seq_order ) TO 'ASIA.map' (FORMAT CSV, DELIMITER ' ');

perl -i -pe's/"//g' ASIA.ped
perl -i -pe's/ /\t/g' ASIA.pop
plink --file ASIA --make-bed -out ASIA
vi par.PED.EIGENSTRAT

genotypename: ASIA.ped
snpname: ASIA.map 
indivname: ASIA.ped
outputformat: EIGENSTRAT
genotypeoutname: ASIA.geno
snpoutname: ASIA.snp
indivoutname: ASIA.ind
familynames: NO

convertf -p par.PED.EIGENSTRAT
cp ASIA.pop ASIA.ind
--R
library(admixr)

# import the data to the snps object:
snps <- eigenstrat("ASIA")

# create a list of populations that you want to test -- these must 
# correspond to those you picked in your query:
pops <- c('Malay', 'Uzbeks', 'Peruvian', 'Iranians', 'Estonians', 'Pathan','Egyptians')

# run the analysis with the chimp as the outgroup, the Denisovans as the next branch 
# the Yoruba as the last branch, and the pops list as your test populations: 
result <- d(W = pops, X = "Yoruba", Y = "Denisovan", Z = "Primate_Chimp", data = snps)

--Since you probably don't have X windows working, save the results like so:
write.csv(result, file = "result.csv")

scp ssh team7@172.25.20.27:SING_CH_F_R C:\Users\abdul\OneDrive\Documents\R\Genomics
scp ssh team7@172.25.20.27:SING_CH_F_R.eigenval C:\Users\e0191963\Downloads
endowment@bankbook7

\copy ( SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE i.family_id LIKE 'Singapore_Chinese' AND d.dataset_name = 'SGVP_b37' ORDER BY i.individuals_id ) TO 'SING.ped' (FORMAT CSV, DELIMITER ' '); 

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'SGVP_b37' ORDER BY ds.seq_order ) TO 'SING.map' (FORMAT CSV, DELIMITER ' ');

perl -i -pe's/"//g' SING.ped 
plink --file SING --make-bed -out SING
plink --bfile SING --hardy --chr 1 --out SING1 
grep 'ALL' SING1.hwe > SING1r.hwe 

--Miscegenation effect
SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE d.dataset_name = 'Reich_v37_2_ALL' 
AND i.family_id IN ('Yoruba', 'AfricanAmerican', 'UtahWhite') 
AND i.average_age = 0 
ORDER BY i.individuals_id;

\copy ( SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE d.dataset_name = 'Reich_v37_2_ALL' AND i.family_id IN ('Yoruba', 'AfricanAmerican', 'UtahWhite') AND i.average_age = 0 ORDER BY i.individuals_id ) TO 'AMERICANS.ped' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'Reich_v37_2_ALL' ORDER BY ds.seq_order ) TO 'AMERICANS.map' (FORMAT CSV, DELIMITER ' ');

perl -i -pe's/"//g' AMERICANS.ped
--Here we will apply a data quality step using "--mind 0.03." This parameter (Links to an external site.) will filter out any genomes with more than 3% un-scored or missing SNPs, retaining only high quality genomes. 

plink --file AMERICANS --mind 0.03 --recode --out AMERICANSC
--gene 0 removes SNPs not scored in genomes
plink --file AMERICANSC --geno 0 --chr X --make-bed -out AMERICANSX

time admixture -j2 AMERICANSX.bed 2

--Repeat the analysis with, say, the biggest autosome, i.e. chromosome 1, 
--75%
plink --file AMERICANSC --geno 0 --chr 1 --make-bed -out AMERICANS1
time admixture -j2 AMERICANS1.bed 2

--Or how about with all 22 autosomes combined (but this will take longer to analyze):

plink --file AMERICANSC --geno 0 --chr 1-22 --make-bed -out AMERICANS122
time admixture -j2 AMERICANS122.bed 2
--Or how about the smallest autosome: 

plink --file AMERICANSC --geno 0 --chr 22 --make-bed -out AMERICANS22
time admixture -j2 AMERICANS22.bed 2

projectname <- "AMERICANS122"
KNum <- 2
fileType <- "Q"

# Ingest the Q file
Q=read.table( paste(projectname,KNum,fileType,sep="."), sep=" ", header=FALSE )
Qmat=as.matrix(Q)

# We also need the FAM file:
fam=read.table(paste(projectname,"fam",sep="."))
fams <- fam[c(1,2)]

# Create a fused table from the Q file and the FAM file:
fusedlist = cbind(fams, Qmat)

# Calculate the means by family_id
means <- aggregate(fusedlist[, 3:4], list(fusedlist$V1), mean)
means

# Extract values from one of the KNum buckets -- here column 3 is 
# giving us the proportion of African ancestry:
AfricanAmerican <- means[ which(means$Group=='AfricanAmerican'), 3 ]
Caucasian <- means[ which(means$Group=='UtahWhite'), 3 ]
Yoruba <- means[ which(means$Group=='Yoruba'), 3 ]

# Calculate the degree to which African-Americans have 
# this bucket relative to how much the Yoruba have it:
(AfricanAmerican - Caucasian) / (Yoruba - Caucasian)

--Singapore vs America PCAs 
SELECT d.dataset_name, count(*) AS "Number of SNPs" 
FROM datasets d NATURAL JOIN datasets_snps ds
GROUP BY d.dataset_name;

--Number and percent of American genomes by race/ethnicity:

SELECT i.country, i.family_id, count(*) AS "Number of Individuals", 
   round( 100* CAST (count(*) AS FLOAT)/t.total ) AS "Percent" 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g, 
   ( SELECT count(*) AS "total" 
     FROM datasets d NATURAL JOIN individuals i 
     WHERE d.dataset_name = 'PGP_AMERICANS'
   ) t 
WHERE d.dataset_name = 'PGP_AMERICANS'
GROUP BY i.country, i.family_id, t.total
ORDER BY count(*) DESC;

--Number and percent of Singaporean genomes by race/ethnicity:

SELECT i.country, i.family_id, count(*) AS "Number of Individuals", 
   round( 100* CAST (count(*) AS FLOAT)/t.total ) AS "Percent" 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g, 
   ( SELECT count(*) AS "total" 
     FROM datasets d NATURAL JOIN individuals i 
     WHERE d.dataset_name = 'SGVP_b37'
   ) t 
WHERE d.dataset_name = 'SGVP_b37'
GROUP BY i.country, i.family_id, t.total
ORDER BY count(*) DESC;

--Selecting SG Chinese
SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE d.dataset_name = 'SGVP_b37' 
AND i.family_id = 'Singapore_Chinese' 
ORDER BY i.individuals_id;

\copy ( SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE d.dataset_name = 'SGVP_b37' AND i.family_id = 'Singapore_Chinese' ORDER BY i.individuals_id ) TO 'SING.ped' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'SGVP_b37' ORDER BY ds.seq_order ) TO 'SING.map' (FORMAT CSV, DELIMITER ' ');

--Selecting PRC Chinese
SELECT d.dataset_name, i.country, i.family_id, count(*) AS "Number of Individuals" 
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE g.group_name = 'EastAsia'
GROUP BY d.dataset_name, i.country, i.family_id 
ORDER BY i.family_id;

SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype  
FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g 
WHERE d.dataset_name = 'HGDP' 
AND i.family_id IN ('Dai', 'Daur', 'Han_N', 'Han_S', 'Han', 'HanBeijing', 'Hezhen', 
    'Lahu', 'Miaozu', 'Naxi', 'Oroqen', 'She', 'Tu', 'Tujia', 'Xibo', 'Yizu') 
ORDER BY i.individuals_id;

\copy ( SELECT i.family_id, i.individual_id, i.paternal_id, i.maternal_id, i.sex, i.phenotype, i.snps FROM datasets d NATURAL JOIN individuals i NATURAL JOIN groupings g WHERE d.dataset_name = 'HGDP' AND i.family_id IN ('Dai', 'Daur', 'Han_N', 'Han_S', 'Han', 'HanBeijing', 'Hezhen', 'Lahu', 'Miaozu', 'Naxi', 'Oroqen', 'She', 'Tu', 'Tujia', 'Xibo', 'Yizu') ORDER BY i.individuals_id ) TO 'CHINESE.ped' (FORMAT CSV, DELIMITER ' ');

\copy ( SELECT s.chromosome_id, s.snp_id, s.genetic_distance, s.base_pair FROM datasets d NATURAL JOIN datasets_snps ds NATURAL JOIN snps s WHERE d.dataset_name = 'HGDP' ORDER BY ds.seq_order ) TO 'CHINESE.map' (FORMAT CSV, DELIMITER ' ');

--PLINK transformations
perl -i -pe's/"//g' SING.ped
plink --file SING --make-bed -out SING

perl -i -pe's/"//g' CHINESE.ped
plink --file CHINESE --make-bed -out CHINESE

--Merging Datasets 
plink --bfile CHINESE --write-snplist --out CHINESE
plink --bfile SING --extract CHINESE.snplist --make-bed --out SING
--Now the SING files are a lot smaller. Let's see if we can merge them:

plink --bfile SING --bmerge CHINESE.bed CHINESE.bim CHINESE.fam --make-bed --out SING_CH
--As is not unusual, we've got a bunch of alleles that are greater than just bi-allelic, which means we can can use the flipping method to try to reduce these: 

plink --bfile CHINESE --flip SING_CH-merge.missnp --make-bed --out CHINESE_F
--So we've now created a set of CHINESE_F files that have about 25,000 SNPs flipped. We can try the merge again:

plink --bfile SING --bmerge CHINESE_F.bed CHINESE_F.bim CHINESE_F.fam --make-bed --out SING_CH_F
--But again we have 16 alleles that are still problematic. Let's just ignore those by excluding them from our datasets:

plink --bfile SING --exclude SING_CH_F-merge.missnp --make-bed --out SING_R 
plink --bfile CHINESE_F --exclude SING_CH_F-merge.missnp --make-bed --out CHINESE_F_R
--And now I can merge them anew and then make a PCA: 

plink --bfile SING_R --bmerge CHINESE_F_R.bed CHINESE_F_R.bim CHINESE_F_R.fam --make-bed --out SING_CH_F_R
plink --bfile SING_CH_F_R --pca 6 --out SING_CH_F_R

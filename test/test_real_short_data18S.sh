mkdir -p real_short_data_test

wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1V4cbazPlErBfjCSiDJsaiIFS1uG4hD5U&confirm=t' -O real_short_data_test18S/PM0224_R1.fastq.gz
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1n1BdtR390xxvTQVHIdgTEOv9s4C0iV4J&confirm=t' -O real_short_data_test18S/PM0224_R2.fastq.gz
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1Yl4HjQbPwSZ4onIWsRRIIGuab47TePU2&confirm=t' -O real_short_data_test18S/PM0324_R1.fastq.gz
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1z404T7m_c3fnl_N9lgGTdoCs6w5YMaZC&confirm=t' -O real_short_data_test18S/PM0324_R2.fastq.gz
 
ampwrap short -i real_short_data_test18S -d dada2_pr2_5.1.1 -a GTGYCAGCMGCCGCGGTAA -A CCGYCAATTYMTTTRAGTTT -l 370 -o real_short_data18S_test_output

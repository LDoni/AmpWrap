mkdir -p short
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=16nTZKwVmxrFkrT-26-IZtlMetjqDTO3r&confirm=t' -O short/S2_11_L001_R2_001.fastq.gz
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1zHKpcZwgNRCe9_h8BqAJZJsG1OyFRW8_&confirm=t' -O short/S2_11_L001_R1_001.fastq.gz
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1oQ2yNHI1JPuu2-NOq3IMdUBq2It8U3P9&confirm=t' -O short/S1_10_L001_R2_001.fastq.gz
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1RmrDN98kDsxc40pVI2rpmP4LRNCYlvxT&confirm=t' -O short/S1_10_L001_R1_001.fastq.gz


ampwrap short -i short -a GTGYCAGCMGCCGCGGTAA -A CCGYCAATTYMTTTRAGTTT -l 372  -o short_test_output







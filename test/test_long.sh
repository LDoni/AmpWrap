mkdir -p long

wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=1_9oDQGAiKlj9kuV_vSAXsDEuTit6HKAh&confirm=t' -O long/ampwrap_long_03.fastq
wget --no-check-certificate 'https://drive.usercontent.google.com/download?export=download&id=18HD6vbQ2jcxc4ETbQwV3KQsKW7rRADA_&confirm=t' -O long/ampwrap_long_01.fastq



ampwrap long -i long -o long_test_output







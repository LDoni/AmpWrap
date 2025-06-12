for i in AmpWrap_long  AmpWrap_short  ampwrap  scripts  snakefile.long  snakefile.short
do
	cp -r ampwrap/$i $CONDA_PREFIX/bin
	chmod -R +x $CONDA_PREFIX/bin/$i
done

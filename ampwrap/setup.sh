for i in AmpWrap_long  AmpWrap_short  ampwrap  scripts  snakefile.long  snakefile.short
do
	echo cp -r ampwrap/$i $CONDA_PREFIX/bin
	echo chmod -R +x $CONDA_PREFIX/bin/$i
done

FROM ecogenomic/gtdbtk:2.7.2

# CTS mounts the refdata tarball's extracted contents at /ref_data. The R232
# tarball has a top-level release232/ wrapper directory (CTS does not strip
# it), so the actual gtdbtk DB dirs (skani/, markers/, msa/, pplacer/, ...)
# end up under /ref_data/release232/. Point GTDBTK_DATA_PATH there.
#
# This image is therefore tied to GTDB release R232. A future GTDB release
# will need a new image (cdm_gtdbtk:0.2.0 etc.) that points at the new
# wrapper directory name (release233/, release234/, ...).
ENV GTDBTK_DATA_PATH=/ref_data/release232

# Upstream image already sets ENTRYPOINT ["gtdbtk"] and CMD ["--help"],
# so we don't need to declare them again.

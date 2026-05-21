FROM ecogenomic/gtdbtk:2.7.2

# CTS mounts refdata at /ref_data. The upstream image defaults to /refdata
# via GTDBTK_DATA_PATH; override so gtdbtk reads from where CTS mounts it.
ENV GTDBTK_DATA_PATH=/ref_data

# Upstream image already sets ENTRYPOINT ["gtdbtk"] and CMD ["--help"],
# so we don't need to declare them again.

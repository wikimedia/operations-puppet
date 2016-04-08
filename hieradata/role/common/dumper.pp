# Dump servers are seeing the dreaded 'Lost parent'
# message at the end of perfectly fine job runs; this
# should eliminate those messages
hhvm::extra::fcgi:
  hhvm:
    server:
      light_process_count: 0
      light_process_file_prefix:
hhvm::extra::cli:
  hhvm:
    server:
      light_process_count: 0
      light_process_file_prefix:

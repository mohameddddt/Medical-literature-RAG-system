-- Prevents re-running ingestion from silently doubling the documents table.
-- content_hash is a stored generated column so it can carry a real index
-- (content itself can exceed Postgres's btree row-size limit).

alter table documents
  add column if not exists content_hash text generated always as (md5(content)) stored;

create unique index if not exists documents_pubid_content_hash_uq
  on documents (pubid, content_hash);

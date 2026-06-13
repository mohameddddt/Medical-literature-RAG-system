-- Vector extension
create extension if not exists vector;

-- Documents (one row = one embedded passage)
create table if not exists documents (
  id         bigint generated always as identity primary key,
  pubid      text,                       -- PubMed ID from the dataset
  question   text,                       -- the source question (optional, useful context)
  content    text not null,              -- the passage text that was embedded
  metadata   jsonb not null default '{}'::jsonb,
  embedding  vector(768)                 -- MedCPT dim. Use vector(1536) for OpenAI small.
);

-- Approximate-NN index. 768 <= 2000, so the plain `vector` type indexes fine.
create index if not exists documents_embedding_hnsw
  on documents using hnsw (embedding vector_cosine_ops);

-- Optional metadata filter index
create index if not exists documents_metadata_gin
  on documents using gin (metadata);

-- Similarity search RPC, called from the API
create or replace function match_documents (
  query_embedding vector(768),
  match_count int default 5,
  filter jsonb default '{}'::jsonb
)
returns table (
  id         bigint,
  pubid      text,
  content    text,
  metadata   jsonb,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    d.id,
    d.pubid,
    d.content,
    d.metadata,
    1 - (d.embedding <=> query_embedding) as similarity
  from documents d
  where d.metadata @> filter
  order by d.embedding <=> query_embedding
  limit match_count;
end;
$$;
"""
Stage 3 & 4: Embedding + Indexing
Embeds chunks with Vertex AI Embeddings and stores them in Cloud SQL
(Postgres + pgvector) via LangChain's PGVector integration.

Assumes the Cloud SQL Auth Proxy is running locally on 127.0.0.1:5432,
pointed at the rag-pipeline-501417-pg instance. Start it in a separate
Cloud Shell tab before running this script:

    ./cloud-sql-proxy rag-pipeline-501417:europe-west2:rag-pipeline-501417-pg
"""

from google.cloud import secretmanager
from langchain_google_vertexai import VertexAIEmbeddings
from langchain_postgres import PGVector
from langchain_core.documents import Document

PROJECT_ID = "rag-pipeline-501417"
REGION = "europe-west2"

DB_HOST = "127.0.0.1"  # Cloud SQL Auth Proxy, not the public IP
DB_PORT = 5432
DB_NAME = "ragdb"
DB_USER = "rag_pipeline"
SECRET_ID = "rag-pipeline-501417-db-password"

COLLECTION_NAME = "rag_poc_chunks"
EMBEDDING_MODEL = "text-embedding-004"


def get_db_password() -> str:
    """Fetch the DB password from Secret Manager rather than hardcoding it."""
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{PROJECT_ID}/secrets/{SECRET_ID}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")


def get_connection_string() -> str:
    password = get_db_password()
    return f"postgresql+psycopg://{DB_USER}:{password}@{DB_HOST}:{DB_PORT}/{DB_NAME}"


def get_embeddings():
    return VertexAIEmbeddings(
        project=PROJECT_ID,
        location=REGION,
        model_name=EMBEDDING_MODEL,
    )


def embed_and_store(chunks: list[Document]) -> PGVector:
    """
    Embed each chunk and upsert it into the pgvector table.
    Returns the PGVector store, ready to be used for retrieval.
    """
    embeddings = get_embeddings()
    connection_string = get_connection_string()

    vectorstore = PGVector(
        embeddings=embeddings,
        collection_name=COLLECTION_NAME,
        connection=connection_string,
        use_jsonb=True,
    )

    ids = vectorstore.add_documents(chunks)
    print(f"Embedded and stored {len(ids)} chunk(s) in collection '{COLLECTION_NAME}'")
    return vectorstore


if __name__ == "__main__":
    from ingest import load_documents_from_bucket
    from chunk import chunk_documents

    docs = load_documents_from_bucket()
    chunks = chunk_documents(docs)
    embed_and_store(chunks)
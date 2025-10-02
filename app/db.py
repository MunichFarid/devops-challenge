import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase

host = os.getenv("DB_HOST", "host.docker.internal")
port = os.getenv("DB_PORT", "5432")
name = os.getenv("DB_NAME", "orders_db")
user = os.getenv("DB_USER", "orders_user")
pwd = os.getenv("DB_PASSWORD", "orders_pass")

DATABASE_URL = f"postgresql+psycopg://{user}:{pwd}@{host}:{port}/{name}"

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

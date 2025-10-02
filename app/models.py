from decimal import Decimal
from sqlalchemy import Integer, Numeric
from sqlalchemy.orm import Mapped, mapped_column
from .db import Base


class Order(Base):
    __tablename__ = "orders"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    # keep money precise; Numeric returns Decimal
    amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)

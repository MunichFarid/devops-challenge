from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, Field, condecimal


class OrderCreate(BaseModel):
    id: Optional[int] = Field(default=None, ge=1)
    amount: condecimal(max_digits=10, decimal_places=2)  # -> Decimal


class OrderOut(BaseModel):
    id: int
    amount: Decimal  # Pydantic v2 serializes Decimal safely

from contextlib import asynccontextmanager
from pathlib import Path
from decimal import Decimal

from fastapi import FastAPI, Depends, HTTPException, Request, status
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .db import Base, engine, get_db
from .models import Order
from .schemas import OrderCreate, OrderOut
from prometheus_fastapi_instrumentator import Instrumentator

TEMPLATE_DIR = Path(__file__).parent / "templates"
templates = Jinja2Templates(directory=str(TEMPLATE_DIR))


@asynccontextmanager
async def lifespan(app: FastAPI):
    # create DB tables at startup
    Base.metadata.create_all(bind=engine)
    yield
    # no teardown needed


app = FastAPI(title="Orders API", lifespan=lifespan)


@app.get("/health")
def health(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception as e:
        return {"status": "degraded", "error": str(e)}


@app.post("/orders", response_model=OrderOut, status_code=status.HTTP_201_CREATED)
def create_order(payload: OrderCreate, db: Session = Depends(get_db)):
    order = Order(id=payload.id, amount=Decimal(payload.amount))
    db.add(order)
    try:
        db.commit()
        db.refresh(order)
    except IntegrityError as e:
        db.rollback()
        # likely duplicate id if user supplied one
        raise HTTPException(
            status_code=400, detail="Order with this id already exists"
        ) from e
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=400, detail=f"Could not create order: {e}"
        ) from e
    return OrderOut(id=order.id, amount=order.amount)


@app.get("/orders", response_model=list[OrderOut])
def list_orders(db: Session = Depends(get_db)):
    orders = db.query(Order).order_by(Order.id.asc()).all()
    return [OrderOut(id=o.id, amount=o.amount) for o in orders]


@app.get("/", response_class=HTMLResponse)
def index(request: Request, db: Session = Depends(get_db)):
    orders = db.query(Order).order_by(Order.id.asc()).all()
    return templates.TemplateResponse(
        "index.html", {"request": request, "orders": orders}
    )


@app.on_event("startup")
def _init_db():
    Base.metadata.create_all(bind=engine)


Instrumentator().instrument(app).expose(
    app, endpoint="/metrics", include_in_schema=False, should_gzip=True
)

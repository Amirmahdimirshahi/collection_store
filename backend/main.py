
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from database import (
    create_tables,
    add_product,
    get_products,
    update_product,
    delete_product
)


app = FastAPI(
    title="Collection Store API",
    description="Smart Collectibles Store",
    version="1.0.0"
)


create_tables()


class Product(BaseModel):
    name: str
    category: str
    description: str = ""
    price: int
    quantity: int = 0


@app.get("/")
def home():
    return {
        "message": "Welcome to Collection Store!",
        "status": "running"
    }


@app.get("/products")
def products_list():
    return get_products()


@app.post("/products")
def create_product(product: Product):

    add_product(
        product.name,
        product.category,
        product.description,
        product.price,
        product.quantity
    )

    return {
        "message": "Product added successfully!"
    }


@app.put("/products/{product_id}")
def edit_product(product_id: int, product: Product):

    updated = update_product(
        product_id,
        product.name,
        product.category,
        product.description,
        product.price,
        product.quantity
    )

    if not updated:
        raise HTTPException(
            status_code=404,
            detail="Product not found"
        )

    return {
        "message": "Product updated successfully!"
    }


@app.delete("/products/{product_id}")
def remove_product(product_id: int):

    deleted = delete_product(product_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="Product not found"
        )

    return {
        "message": "Product deleted successfully!"
    }

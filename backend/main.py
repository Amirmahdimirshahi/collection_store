
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from auth_service import generate_otp, verify_otp

from database import (
    create_tables,
    add_product,
    get_products,
    update_product,
    delete_product,
    add_user,
    create_order,
    get_user_by_phone,
    get_user_by_id,
    get_user_orders
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


class SendCodeRequest(BaseModel):
    phone_number: str


class VerifyCodeRequest(BaseModel):
    phone_number: str
    full_name: str
    code: str


class OrderItemRequest(BaseModel):
    product_id: int
    quantity: int


class CreateOrderRequest(BaseModel):
    user_id: int
    items: list[OrderItemRequest]


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


@app.post("/auth/send-code")
def send_login_code(request: SendCodeRequest):
    phone = request.phone_number.strip()

    if len(phone) != 11 or not phone.startswith("09") or not phone.isdigit():
        raise HTTPException(
            status_code=400,
            detail="Invalid phone number"
        )

    generate_otp(phone)

    return {
        "message": "Verification code generated successfully"
    }


@app.post("/auth/verify-code")
def verify_login_code(request: VerifyCodeRequest):
    phone = request.phone_number.strip()
    name = request.full_name.strip()
    code = request.code.strip()

    if not phone.isdigit() or len(phone) != 11 or not phone.startswith("09"):
        raise HTTPException(
            status_code=400,
            detail="Invalid phone number"
        )

    if not name:
        raise HTTPException(
            status_code=400,
            detail="Full name is required"
        )

    if not verify_otp(phone, code):
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired code"
        )

    user = get_user_by_phone(phone)

    if not user:
        add_user(phone, name)
        user = get_user_by_phone(phone)

    return {
        "message": "Login successful",
        "user": user
    }


@app.post("/orders")
def create_new_order(request: CreateOrderRequest):
    if not request.items:
        raise HTTPException(
            status_code=400,
            detail="سبد خرید خالی است."
        )

    try:
        order = create_order(
            request.user_id,
            [
                {
                    "product_id": item.product_id,
                    "quantity": item.quantity
                }
                for item in request.items
            ]
        )

        return {
            "message": "سفارش با موفقیت ثبت شد.",
            "order": order
        }

    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail=str(error)
        )


@app.get("/users/{user_id}/orders")
def read_user_orders(user_id: int):
    user = get_user_by_id(user_id)

    if not user:
        raise HTTPException(
            status_code=404,
            detail="کاربر پیدا نشد."
        )

    return {
        "orders": get_user_orders(user_id)
    }

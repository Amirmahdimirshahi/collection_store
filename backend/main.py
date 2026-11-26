
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel

from auth_service import generate_otp, verify_otp
from security import create_access_token, verify_access_token

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
    get_user_orders,
    get_all_orders,
    update_order_status,
    add_favorite,
    remove_favorite,
    get_user_favorites,
)


app = FastAPI(
    title="Collection Store API",
    description="Smart Collectibles Store",
    version="1.0.0"
)

create_tables()

security_scheme = HTTPBearer()


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
    items: list[OrderItemRequest]


class UpdateOrderStatusRequest(BaseModel):
    status: str


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme)
):
    token = credentials.credentials

    token_data = verify_access_token(token)

    if token_data is None:
        raise HTTPException(
            status_code=401,
            detail="توکن نامعتبر یا منقضی شده است."
        )

    user = get_user_by_id(token_data["user_id"])

    if not user:
        raise HTTPException(
            status_code=401,
            detail="کاربر پیدا نشد."
        )

    return user


def get_admin_user(
    current_user: dict = Depends(get_current_user)
):
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=403,
            detail="شما اجازه دسترسی به این بخش را ندارید."
        )

    return current_user


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
def create_product(
    product: Product,
    admin: dict = Depends(get_admin_user)
):
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
def edit_product(
    product_id: int,
    product: Product,
    admin: dict = Depends(get_admin_user)
):
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
def remove_product_api(
    product_id: int,
    admin: dict = Depends(get_admin_user)
):
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

    if (
        len(phone) != 11
        or not phone.startswith("09")
        or not phone.isdigit()
    ):
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

    if (
        not phone.isdigit()
        or len(phone) != 11
        or not phone.startswith("09")
    ):
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

    access_token = create_access_token(user)

    return {
        "message": "Login successful",
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }


@app.get("/auth/me")
def read_current_user(
    current_user: dict = Depends(get_current_user)
):
    return {
        "user": current_user
    }


@app.get("/favorites")
def read_favorites(
    current_user: dict = Depends(get_current_user)
):
    favorites = get_user_favorites(current_user["id"])

    return {
        "favorites": favorites
    }


@app.post("/favorites/{product_id}")
def create_favorite(
    product_id: int,
    current_user: dict = Depends(get_current_user)
):
    try:
        add_favorite(
            current_user["id"],
            product_id
        )

        return {
            "message": "محصول به علاقه‌مندی‌ها اضافه شد.",
            "product_id": product_id
        }

    except ValueError as error:
        raise HTTPException(
            status_code=404,
            detail=str(error)
        )


@app.delete("/favorites/{product_id}")
def delete_favorite(
    product_id: int,
    current_user: dict = Depends(get_current_user)
):
    deleted = remove_favorite(
        current_user["id"],
        product_id
    )

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="این محصول در علاقه‌مندی‌های شما وجود ندارد."
        )

    return {
        "message": "محصول از علاقه‌مندی‌ها حذف شد.",
        "product_id": product_id
    }


@app.post("/orders")
def create_new_order(
    request: CreateOrderRequest,
    current_user: dict = Depends(get_current_user)
):
    if not request.items:
        raise HTTPException(
            status_code=400,
            detail="سبد خرید خالی است."
        )

    try:
        order = create_order(
            current_user["id"],
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
def read_user_orders(
    user_id: int,
    current_user: dict = Depends(get_current_user)
):
    if user_id != current_user["id"]:
        raise HTTPException(
            status_code=403,
            detail="شما اجازه مشاهده سفارش‌های این کاربر را ندارید."
        )

    return {
        "orders": get_user_orders(current_user["id"])
    }


@app.get("/admin/orders")
def read_all_orders(
    admin: dict = Depends(get_admin_user)
):
    return {
        "orders": get_all_orders()
    }


@app.put("/admin/orders/{order_id}/status")
def change_order_status(
    order_id: int,
    request: UpdateOrderStatusRequest,
    admin: dict = Depends(get_admin_user)
):
    try:
        updated = update_order_status(
            order_id,
            request.status
        )

        if not updated:
            raise HTTPException(
                status_code=404,
                detail="سفارش پیدا نشد."
            )

        return {
            "message": "وضعیت سفارش با موفقیت تغییر کرد.",
            "order_id": order_id,
            "status": request.status
        }

    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail=str(error)
        )


from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel

from auth_service import generate_otp, verify_otp

from security import (
    create_access_token,
    verify_access_token,
    hash_password,
    verify_password,
)

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
    set_user_password,
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


class CheckPhoneRequest(BaseModel):
    phone_number: str


class LoginRequest(BaseModel):
    phone_number: str
    password: str


class VerifyCodeRequest(BaseModel):
    phone_number: str
    full_name: str | None = None
    password: str
    code: str


class ResetPasswordRequest(BaseModel):
    phone_number: str
    code: str
    new_password: str


class OrderItemRequest(BaseModel):
    product_id: int
    quantity: int


class CreateOrderRequest(BaseModel):
    items: list[OrderItemRequest]


class UpdateOrderStatusRequest(BaseModel):
    status: str


def validate_phone(phone: str):
    phone = phone.strip()

    if (
        len(phone) != 11
        or not phone.startswith("09")
        or not phone.isdigit()
    ):
        raise HTTPException(
            status_code=400,
            detail="شماره موبایل معتبر نیست."
        )

    return phone


def validate_password(password: str):
    if len(password) < 8:
        raise HTTPException(
            status_code=400,
            detail="رمز عبور باید حداقل ۸ کاراکتر باشد."
        )

    if len(password) > 128:
        raise HTTPException(
            status_code=400,
            detail="رمز عبور نباید بیشتر از ۱۲۸ کاراکتر باشد."
        )


def public_user(user: dict):
    """
    اطلاعات مجاز کاربر برای ارسال به Flutter
    """

    return {
        "id": user["id"],
        "full_name": user["full_name"],
        "phone_number": user["phone_number"],
        "role": user["role"],
    }


def create_login_response(user: dict):
    """
    ساخت پاسخ مشترک برای ورود کاربران
    """

    safe_user = public_user(user)
    access_token = create_access_token(user)

    return {
        "message": "ورود با موفقیت انجام شد.",
        "access_token": access_token,
        "token_type": "bearer",
        "user": safe_user
    }


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


@app.post("/auth/check-phone")
def check_phone(request: CheckPhoneRequest):
    phone = validate_phone(request.phone_number)

    user = get_user_by_phone(phone)

    if not user:
        return {
            "has_account": False,
            "has_password": False,
            "requires_name": True
        }

    has_password = bool(user.get("password_hash"))

    return {
        "has_account": True,
        "has_password": has_password,
        "requires_name": False
    }


@app.post("/auth/send-code")
def send_login_code(request: SendCodeRequest):
    phone = validate_phone(request.phone_number)

    user = get_user_by_phone(phone)

    if user and user.get("password_hash"):
        raise HTTPException(
            status_code=400,
            detail="این حساب رمز عبور دارد. با رمز عبور وارد شوید."
        )

    generate_otp(phone)

    return {
        "message": "کد تأیید با موفقیت ایجاد شد."
    }

@app.post("/auth/forgot-password/send-code")
def send_password_reset_code(request: SendCodeRequest):
    phone = validate_phone(request.phone_number)

    user = get_user_by_phone(phone)

    if not user:
        raise HTTPException(
            status_code=404,
            detail="حساب کاربری با این شماره موبایل پیدا نشد."
        )

    if not user.get("password_hash"):
        raise HTTPException(
            status_code=400,
            detail="این حساب هنوز رمز عبور ندارد. از روش فعال‌سازی حساب استفاده کنید."
        )

    generate_otp(phone)

    return {
        "message": "کد بازیابی با موفقیت ایجاد شد."
    }


@app.post("/auth/login")
def login_with_password(request: LoginRequest):
    phone = validate_phone(request.phone_number)

    validate_password(request.password)

    user = get_user_by_phone(phone)

    if not user:
        raise HTTPException(
            status_code=401,
            detail="شماره موبایل یا رمز عبور اشتباه است."
        )

    stored_hash = user.get("password_hash")

    if not stored_hash:
        raise HTTPException(
            status_code=400,
            detail="ابتدا باید حساب خود را با کد تأیید فعال کنید."
        )

    if not verify_password(request.password, stored_hash):
        raise HTTPException(
            status_code=401,
            detail="شماره موبایل یا رمز عبور اشتباه است."
        )

    return create_login_response(user)


@app.post("/auth/verify-code")
def verify_login_code(request: VerifyCodeRequest):
    phone = validate_phone(request.phone_number)

    code = request.code.strip()
    password = request.password

    validate_password(password)

    if not code.isdigit() or len(code) != 6:
        raise HTTPException(
            status_code=400,
            detail="کد تأیید باید ۶ رقم باشد."
        )

    user = get_user_by_phone(phone)

    if user and user.get("password_hash"):
        raise HTTPException(
            status_code=400,
            detail="این حساب قبلاً رمز عبور دارد. از روش ورود با رمز استفاده کنید."
        )

    if not user:
        name = (request.full_name or "").strip()

        if not name:
            raise HTTPException(
                status_code=400,
                detail="نام و نام خانوادگی الزامی است."
            )

    if not verify_otp(phone, code):
        raise HTTPException(
            status_code=400,
            detail="کد تأیید اشتباه است یا اعتبار آن تمام شده است."
        )

    if not user:
        name = request.full_name.strip()

        try:
            add_user(phone, name)
        except Exception:
            raise HTTPException(
                status_code=400,
                detail="ساخت حساب کاربری ناموفق بود."
            )

        user = get_user_by_phone(phone)

    if not user:
        raise HTTPException(
            status_code=500,
            detail="خطا در دریافت اطلاعات کاربر."
        )

    password_hash = hash_password(password)

    saved = set_user_password(
        user["id"],
        password_hash
    )

    if not saved:
        raise HTTPException(
            status_code=500,
            detail="ذخیره رمز عبور ناموفق بود."
        )

    user = get_user_by_id(user["id"])

    return create_login_response(user)


@app.post("/auth/forgot-password/reset")
def reset_password(request: ResetPasswordRequest):
    phone = validate_phone(request.phone_number)

    code = request.code.strip()
    new_password = request.new_password

    validate_password(new_password)

    if not code.isdigit() or len(code) != 6:
        raise HTTPException(
            status_code=400,
            detail="کد تأیید باید ۶ رقم باشد."
        )

    user = get_user_by_phone(phone)

    if not user:
        raise HTTPException(
            status_code=404,
            detail="حساب کاربری پیدا نشد."
        )

    if not user.get("password_hash"):
        raise HTTPException(
            status_code=400,
            detail="این حساب هنوز رمز عبور ندارد."
        )

    if not verify_otp(phone, code):
        raise HTTPException(
            status_code=400,
            detail="کد تأیید اشتباه است یا اعتبار آن تمام شده است."
        )

    password_hash = hash_password(new_password)

    saved = set_user_password(
        user["id"],
        password_hash
    )

    if not saved:
        raise HTTPException(
            status_code=500,
            detail="ذخیره رمز عبور جدید ناموفق بود."
        )

    return {
        "message": "رمز عبور با موفقیت تغییر کرد."
    }


@app.get("/auth/me")
def read_current_user(
    current_user: dict = Depends(get_current_user)
):
    return {
        "user": public_user(current_user)
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

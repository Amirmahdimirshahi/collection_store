
import os
import secrets
import hashlib
import hmac

from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt


SECRET_KEY = os.getenv(
    "JWT_SECRET_KEY",
    "CHANGE_THIS_SECRET_KEY_BEFORE_PRODUCTION_2026"
)

ALGORITHM = "HS256"

ACCESS_TOKEN_EXPIRE_MINUTES = 7 * 24 * 60


SCRYPT_N = 2**14
SCRYPT_R = 8
SCRYPT_P = 1
SCRYPT_KEY_LENGTH = 64
SCRYPT_SALT_LENGTH = 16


def hash_password(password: str) -> str:
    """
    تبدیل رمز عبور به هش امن برای ذخیره در دیتابیس
    """

    if not isinstance(password, str) or not password:
        raise ValueError("رمز عبور نمی‌تواند خالی باشد.")

    salt = secrets.token_bytes(SCRYPT_SALT_LENGTH)

    password_hash = hashlib.scrypt(
        password.encode("utf-8"),
        salt=salt,
        n=SCRYPT_N,
        r=SCRYPT_R,
        p=SCRYPT_P,
        dklen=SCRYPT_KEY_LENGTH
    )

    return (
        f"scrypt${SCRYPT_N}${SCRYPT_R}${SCRYPT_P}"
        f"${salt.hex()}${password_hash.hex()}"
    )


def verify_password(password: str, stored_hash: str) -> bool:
    """
    بررسی رمز عبور واردشده با هش ذخیره‌شده
    """

    if not isinstance(password, str) or not isinstance(stored_hash, str):
        return False

    try:
        algorithm, n, r, p, salt_hex, hash_hex = stored_hash.split("$")

        if algorithm != "scrypt":
            return False

        n = int(n)
        r = int(r)
        p = int(p)

        salt = bytes.fromhex(salt_hex)
        original_hash = bytes.fromhex(hash_hex)

        if n < 2 or n > 2**18 or n & (n - 1):
            return False

        if r < 1 or r > 32 or p < 1 or p > 16:
            return False

        if len(salt) != SCRYPT_SALT_LENGTH:
            return False

        if len(original_hash) != SCRYPT_KEY_LENGTH:
            return False

        new_hash = hashlib.scrypt(
            password.encode("utf-8"),
            salt=salt,
            n=n,
            r=r,
            p=p,
            dklen=len(original_hash)
        )

        return hmac.compare_digest(
            new_hash,
            original_hash
        )

    except (ValueError, TypeError, MemoryError):
        return False


def create_access_token(user: dict) -> str:
    """
    ساخت توکن ورود برای کاربر
    """

    expire = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    payload = {
        "sub": str(user["id"]),
        "role": user["role"],
        "exp": expire,
    }

    return jwt.encode(
        payload,
        SECRET_KEY,
        algorithm=ALGORITHM
    )


def verify_access_token(token: str):
    """
    بررسی اعتبار توکن
    """

    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        user_id = payload.get("sub")
        role = payload.get("role")

        if user_id is None or role is None:
            return None

        return {
            "user_id": int(user_id),
            "role": role
        }

    except (JWTError, ValueError, TypeError):
        return None

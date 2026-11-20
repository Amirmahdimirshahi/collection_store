
import secrets
import hashlib
import time

# کدهای موقت ورود
otp_codes = {}


def generate_otp(phone_number):
    # تولید کد شش رقمی
    code = f"{secrets.randbelow(1000000):06d}"

    # ذخیره هش کد به همراه زمان انقضا
    code_hash = hashlib.sha256(code.encode()).hexdigest()

    otp_codes[phone_number] = {
        "code_hash": code_hash,
        "expires_at": time.time() + 120,
        "attempts": 0
    }

    # نمایش کد فقط در محیط توسعه
    print(f"OTP for {phone_number}: {code}")

    return True


def verify_otp(phone_number, code):
    data = otp_codes.get(phone_number)

    if not data:
        return False

    if time.time() > data["expires_at"]:
        otp_codes.pop(phone_number, None)
        return False

    if data["attempts"] >= 5:
        otp_codes.pop(phone_number, None)
        return False

    code_hash = hashlib.sha256(code.encode()).hexdigest()

    if code_hash != data["code_hash"]:
        data["attempts"] += 1
        return False

    otp_codes.pop(phone_number, None)

    return True

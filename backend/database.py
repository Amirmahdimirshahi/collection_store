
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "collection_store.db"


def connect_db():
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    return connection

def create_tables():
    connection = connect_db()

    connection.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            price INTEGER NOT NULL,
            quantity INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    user_columns = connection.execute(
        "PRAGMA table_info(users)"
    ).fetchall()

    existing_columns = [column["name"] for column in user_columns]

    if user_columns and "phone_number" not in existing_columns:
        user_count = connection.execute(
            "SELECT COUNT(*) FROM users"
        ).fetchone()[0]

        if user_count > 0:
            connection.close()
            raise RuntimeError(
                "جدول کاربران قدیمی دارای اطلاعات است. "
                "قبل از تغییر باید اطلاعات آن مهاجرت داده شود."
            )

        connection.execute("DROP TABLE users")

    connection.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone_number TEXT NOT NULL UNIQUE,
            full_name TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'customer'
                CHECK(role IN ('customer', 'admin')),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    connection.execute("""
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            total_price INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)

    connection.execute("""
        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            product_name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price INTEGER NOT NULL,
            total_price INTEGER NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders(id),
            FOREIGN KEY (product_id) REFERENCES products(id)
        )
    """)

    connection.commit()
    connection.close()


def add_product(name, category, description, price, quantity):
    connection = connect_db()

    cursor = connection.execute("""
        INSERT INTO products
        (name, category, description, price, quantity)
        VALUES (?, ?, ?, ?, ?)
    """, (name, category, description, price, quantity))

    product_id = cursor.lastrowid

    connection.commit()
    connection.close()

    return product_id


def get_products():
    connection = connect_db()

    products = connection.execute("""
        SELECT * FROM products
        ORDER BY id DESC
    """).fetchall()

    connection.close()

    return [dict(product) for product in products]


def get_product_by_id(product_id):
    connection = connect_db()

    product = connection.execute("""
        SELECT * FROM products
        WHERE id = ?
    """, (product_id,)).fetchone()

    connection.close()

    return dict(product) if product else None


def update_product(
    product_id,
    name,
    category,
    description,
    price,
    quantity
):
    connection = connect_db()

    cursor = connection.execute("""
        UPDATE products
        SET name = ?,
            category = ?,
            description = ?,
            price = ?,
            quantity = ?
        WHERE id = ?
    """, (
        name,
        category,
        description,
        price,
        quantity,
        product_id
    ))

    connection.commit()

    updated = cursor.rowcount > 0

    connection.close()

    return updated


def delete_product(product_id):
    connection = connect_db()

    cursor = connection.execute("""
        DELETE FROM products
        WHERE id = ?
    """, (product_id,))

    connection.commit()

    deleted = cursor.rowcount > 0

    connection.close()

    return deleted


def add_user(phone_number, full_name):
    connection = connect_db()

    cursor = connection.execute("""
        INSERT INTO users
        (phone_number, full_name, role)
        VALUES (?, ?, 'customer')
    """, (phone_number, full_name))

    user_id = cursor.lastrowid

    connection.commit()
    connection.close()

    return user_id


def get_user_by_phone(phone_number):
    connection = connect_db()

    user = connection.execute("""
        SELECT * FROM users
        WHERE phone_number = ?
    """, (phone_number,)).fetchone()

    connection.close()

    return dict(user) if user else None


def get_user_by_id(user_id):
    connection = connect_db()

    user = connection.execute("""
        SELECT * FROM users
        WHERE id = ?
    """, (user_id,)).fetchone()

    connection.close()

    return dict(user) if user else None


def get_database_stats():
    connection = connect_db()

    product_count = connection.execute(
        "SELECT COUNT(*) FROM products"
    ).fetchone()[0]

    user_count = connection.execute(
        "SELECT COUNT(*) FROM users"
    ).fetchone()[0]

    connection.close()

    return {
        "products": product_count,
        "users": user_count
    }


if __name__ == "__main__":
    create_tables()

    print("Database is ready!")

    print(get_database_stats())


def create_order(user_id, items):
    connection = connect_db()

    try:
        user = connection.execute(
            "SELECT id FROM users WHERE id = ?",
            (user_id,)
        ).fetchone()

        if not user:
            raise ValueError("کاربر پیدا نشد.")

        total_price = 0
        order_products = []

        for item in items:
            product_id = item["product_id"]
            quantity = item["quantity"]

            if quantity <= 0:
                raise ValueError("تعداد محصول باید بیشتر از صفر باشد.")

            product = connection.execute(
                "SELECT * FROM products WHERE id = ?",
                (product_id,)
            ).fetchone()

            if not product:
                raise ValueError(
                    f"محصول با شناسه {product_id} پیدا نشد."
                )

            if product["quantity"] < quantity:
                raise ValueError(
                    f"موجودی محصول {product['name']} کافی نیست."
                )

            unit_price = product["price"]
            item_total = unit_price * quantity
            total_price += item_total

            order_products.append({
                "product_id": product_id,
                "product_name": product["name"],
                "quantity": quantity,
                "unit_price": unit_price,
                "total_price": item_total
            })

        cursor = connection.execute(
            """
            INSERT INTO orders (user_id, total_price, status)
            VALUES (?, ?, 'pending')
            """,
            (user_id, total_price)
        )

        order_id = cursor.lastrowid

        for item in order_products:
            connection.execute(
                """
                INSERT INTO order_items (
                    order_id,
                    product_id,
                    product_name,
                    quantity,
                    unit_price,
                    total_price
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    order_id,
                    item["product_id"],
                    item["product_name"],
                    item["quantity"],
                    item["unit_price"],
                    item["total_price"]
                )
            )

            connection.execute(
                """
                UPDATE products
                SET quantity = quantity - ?
                WHERE id = ?
                """,
                (item["quantity"], item["product_id"])
            )

        connection.commit()

        return {
            "order_id": order_id,
            "user_id": user_id,
            "total_price": total_price,
            "status": "pending",
            "items": order_products
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        connection.close()
